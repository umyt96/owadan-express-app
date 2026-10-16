import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/address.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../services/address_service.dart';
import '../services/checkout_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_field.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/location_picker_card.dart';
import '../widgets/skeleton.dart';
import 'main_navigation_screen.dart';
import '../services/analytics_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressService = AddressService();
  final _checkoutService = CheckoutService();

  /// Отмеченные в корзине позиции. Если отмечено всё — передаём null, и
  /// сервер оформляет всю корзину (как раньше).
  List<int>? _selectedItemIds() {
    final cart = context.read<CartProvider>();
    if (cart.allSelected) return null;
    return cart.selectedIds.toList();
  }

  late Future<List<Address>> _addressesFuture;
  int? _selectedAddressId;
  bool _addingNew = false;
  bool _isSubmitting = false;
  String? _error;

  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _setDefault = true;
  // Местоположение по GPS (необязательно).
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _addressesFuture = _loadAddresses();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _apartmentController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<List<Address>> _loadAddresses() async {
    final addresses = await _addressService.getAddresses();
    if (addresses.isEmpty) {
      _addingNew = true;
    } else {
      _selectedAddressId = addresses
          .firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          )
          .id;
    }
    return addresses;
  }

  Future<void> _confirmOrder() async {
    final locale = context.read<LocaleProvider>();
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      AppOrder order;
      if (_addingNew) {
        if (_streetController.text.trim().isEmpty ||
            _countryController.text.trim().isEmpty ||
            _phoneController.text.trim().isEmpty) {
          HapticFeedback.mediumImpact();
          setState(() {
            _error = locale.t('checkout_required_fields');
            _isSubmitting = false;
          });
          return;
        }
        order = await _checkoutService.checkout(
          streetAddress: _streetController.text.trim(),
          apartmentAddress: _apartmentController.text.trim(),
          country: _countryController.text.trim(),
          phone: _phoneController.text.trim(),
          setDefault: _setDefault,
          itemIds: _selectedItemIds(),
          latitude: _latitude,
          longitude: _longitude,
        );
      } else {
        if (_selectedAddressId == null) {
          HapticFeedback.mediumImpact();
          setState(() {
            _error = locale.t('checkout_select_address');
            _isSubmitting = false;
          });
          return;
        }
        order = await _checkoutService.checkout(
          addressId: _selectedAddressId,
          itemIds: _selectedItemIds(),
          latitude: _latitude,
          longitude: _longitude,
        );
      }

      if (!mounted) return;
      // Не сбрасываем корзину целиком: невыбранные товары остаются в ней.
      context.read<CartProvider>().loadCart();
      ordersChangedTick.value++;
      AnalyticsService.instance.event('order_placed', data: {'total': order.total});
      HapticFeedback.lightImpact();
      _showSuccessDialog(order);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(AppOrder order) {
    final locale = context.read<LocaleProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        title: locale.t('order_success'),
        codeLabel: locale.t('order_code'),
        code: order.refCode,
        totalLabel: locale.t('total_amount'),
        total: order.total,
        message: locale.t('checkout_contact_message'),
        okLabel: locale.t('ok'),
        onOk: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  /// Блоки появляются по очереди — экран не "выскакивает" целиком.
  Widget _enter(int index, Widget child) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 300 + index * 70),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: GradientAppBar(
        title: Text(locale.t('checkout_title')),
        centerTitle: true,
      ),
      // Итог и кнопка закреплены внизу и поднимаются над клавиатурой.
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: _BottomBar(
          totalLabel: locale.t('total_amount'),
          total: cart.total,
          buttonLabel: locale.t(_isSubmitting ? 'checkout_processing' : 'confirm_order'),
          busy: _isSubmitting,
          onTap: _confirmOrder,
        ),
      ),
      body: FutureBuilder<List<Address>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CheckoutSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text('${locale.t('error')}: ${snapshot.error}'));
          }
          final addresses = snapshot.data ?? [];

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _enter(
                  0,
                  _OrderSummary(
                    title: locale.t('checkout_summary'),
                    items: cart.selectedItems,
                    total: cart.total,
                  ),
                ),
                const SizedBox(height: 22),
                _enter(
                  1,
                  _SectionTitle(
                    icon: HugeIcons.strokeRoundedLocation01,
                    text: locale.t('shipping_address'),
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < addresses.length; i++)
                  _enter(
                    2 + i,
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AddressCard(
                        address: addresses[i],
                        selected: !_addingNew && _selectedAddressId == addresses[i].id,
                        defaultLabel: locale.t('default_badge'),
                        onTap: () => setState(() {
                          _selectedAddressId = addresses[i].id;
                          _addingNew = false;
                          _error = null;
                        }),
                      ),
                    ),
                  ),
                _enter(
                  2 + addresses.length,
                  _NewAddressCard(
                    open: _addingNew,
                    title: locale.t('new_address'),
                    onTap: () => setState(() {
                      _addingNew = true;
                      _error = null;
                    }),
                    form: Column(
                      children: [
                        AppField(
                          controller: _streetController,
                          label: locale.t('street_hint'),
                          icon: HugeIcons.strokeRoundedLocation01,
                          textInputAction: TextInputAction.next,
                          capitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 12),
                        AppField(
                          controller: _apartmentController,
                          label: locale.t('apartment_hint'),
                          icon: HugeIcons.strokeRoundedHome01,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        AppField(
                          controller: _countryController,
                          label: locale.t('region_hint'),
                          icon: HugeIcons.strokeRoundedMapPin,
                          textInputAction: TextInputAction.next,
                          capitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        AppField(
                          controller: _phoneController,
                          label: locale.t('phone_hint'),
                          icon: HugeIcons.strokeRoundedCall,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _setDefault = !_setDefault),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    locale.t('save_as_default'),
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      color: AppColors.headingText,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                CupertinoSwitch(
                                  value: _setDefault,
                                  activeTrackColor: AppColors.accent,
                                  onChanged: (v) => setState(() => _setDefault = v),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _enter(
                  3 + addresses.length,
                  LocationPickerCard(
                    latitude: _latitude,
                    longitude: _longitude,
                    onChanged: (lat, lng) => setState(() {
                      _latitude = lat;
                      _longitude = lng;
                    }),
                  ),
                ),
                // Ошибка появляется и пропадает плавно.
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedAlert02,
                                  color: AppColors.danger,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      color: AppColors.danger,
                                      fontSize: 13.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String text;

  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.11),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(child: HugeIcon(icon: icon, color: AppColors.brand, size: 19)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: AppColors.headingText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Сводка заказа: миниатюры отмеченных товаров внахлёст, их число и сумма.
class _OrderSummary extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final num total;

  const _OrderSummary({required this.title, required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    const shown = 4;
    const size = 46.0;
    const step = 32.0;
    final visible = items.take(shown).toList();
    final extra = items.length - visible.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.subtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientEnd.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: step * (visible.length - 1) + size + (extra > 0 ? step : 0),
            height: size,
            child: Stack(
              children: [
                for (var i = 0; i < visible.length; i++)
                  Positioned(
                    left: i * step,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.subtle,
                        border: Border.all(color: AppColors.card, width: 2.5),
                      ),
                      child: ClipOval(
                        child: visible[i].item.image != null
                            ? AppNetworkImage(
                                url: visible[i].item.image,
                                fit: BoxFit.cover,
                                alignment: Alignment.bottomCenter,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                if (extra > 0)
                  Positioned(
                    left: visible.length * step,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withOpacity(0.12),
                        border: Border.all(color: AppColors.card, width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          '+$extra',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            color: AppColors.accent,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.headingText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.accent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$total ТМТ',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Сохранённый адрес: выбранный получает акцентную рамку и галочку.
class _AddressCard extends StatelessWidget {
  final Address address;
  final bool selected;
  final String defaultLabel;
  final VoidCallback onTap;

  const _AddressCard({
    required this.address,
    required this.selected,
    required this.defaultLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      if ((address.apartmentAddress ?? '').trim().isNotEmpty) address.apartmentAddress!.trim(),
      address.country,
    ].where((e) => e.isNotEmpty).join(', ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? AppColors.accent.withOpacity(AppColors.isDark ? 0.14 : 0.06) : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.subtle,
          width: selected ? 1.6 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RadioDot(selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              address.streetAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                color: AppColors.headingText,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                defaultLabel,
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          details,
                          style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 13.5),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedCall, size: 15, color: AppColors.bodyText),
                          const SizedBox(width: 6),
                          Text(
                            address.phone,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              color: AppColors.headingText,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Новый адрес": карточка-переключатель; при выборе раскрывает форму.
class _NewAddressCard extends StatelessWidget {
  final bool open;
  final String title;
  final VoidCallback onTap;
  final Widget form;

  const _NewAddressCard({required this.open, required this.title, required this.onTap, required this.form});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: open ? AppColors.accent.withOpacity(AppColors.isDark ? 0.14 : 0.06) : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: open ? AppColors.accent : AppColors.subtle,
          width: open ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _RadioDot(selected: open),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.headingText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 20, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: form,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Круглая отметка выбора: пустое кольцо → заливка с галочкой.
class _RadioDot extends StatelessWidget {
  final bool selected;

  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.accent : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.bodyText.withOpacity(0.5),
          width: 1.6,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: const Center(
          child: HugeIcon(icon: HugeIcons.strokeRoundedTick02, size: 14, color: Colors.white, strokeWidth: 2.6),
        ),
      ),
    );
  }
}

/// Нижняя панель: сумма слева, кнопка подтверждения справа.
class _BottomBar extends StatelessWidget {
  final String totalLabel;
  final num total;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onTap;

  const _BottomBar({
    required this.totalLabel,
    required this.total,
    required this.buttonLabel,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppColors.isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                totalLabel,
                style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 12.5),
              ),
              Text(
                '$total ТМТ',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  color: AppColors.headingText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: busy ? null : onTap,
                  child: Center(
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                buttonLabel,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Диалог успеха: большая галочка с пружиной, код заказа и сумма.
class _SuccessDialog extends StatelessWidget {
  final String title;
  final String codeLabel;
  final String code;
  final String totalLabel;
  final num? total;
  final String message;
  final String okLabel;
  final VoidCallback onOk;

  const _SuccessDialog({
    required this.title,
    required this.codeLabel,
    required this.code,
    required this.totalLabel,
    required this.total,
    required this.message,
    required this.okLabel,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: const Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedTick02,
                        size: 30,
                        color: Colors.white,
                        strokeWidth: 2.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: AppColors.headingText,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.subtle, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _InfoRow(label: codeLabel, value: code, copyable: true),
                  if (total != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(label: totalLabel, value: '$total ТМТ', accent: true),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onOk,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  okLabel,
                  style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final bool copyable;

  const _InfoRow({required this.label, required this.value, this.accent = false, this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 13.5)),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Код заказа можно скопировать, коснувшись его.
            onTap: copyable
                ? () {
                    Clipboard.setData(ClipboardData(text: value));
                    HapticFeedback.selectionClick();
                  }
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: accent ? AppColors.accent : AppColors.headingText,
                      fontSize: accent ? 17 : 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 6),
                  HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 16, color: AppColors.bodyText),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Заглушка загрузки: сводка и две карточки адреса.
class _CheckoutSkeleton extends StatelessWidget {
  const _CheckoutSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPulse(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 78, radius: 22),
            SizedBox(height: 26),
            SkeletonBox(width: 170, height: 22),
            SizedBox(height: 14),
            SkeletonBox(height: 96, radius: 20),
            SizedBox(height: 10),
            SkeletonBox(height: 60, radius: 20),
          ],
        ),
      ),
    );
  }
}
