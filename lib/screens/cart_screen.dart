import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../models/cart_item.dart';
import '../theme/app_motion.dart';
import '../utils/auth_guard.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/guest_login_button.dart';
import '../widgets/illustrated_empty_state.dart';
import '../widgets/skeleton.dart';
import 'product_detail_screen.dart';
import 'checkout_screen.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  bool _applyingCoupon = false;
  bool _couponOpen = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _applyingCoupon = true);
    final ok = await context.read<CartProvider>().applyCoupon(code);
    if (!mounted) return;
    setState(() => _applyingCoupon = false);
    final cart = context.read<CartProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok
              ? context.read<LocaleProvider>().t('coupon_applied')
              : (cart.errorMessage ??
                  context.read<LocaleProvider>().t('coupon_error')))),
    );
  }

  Future<void> _goToCheckout() async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  Future<void> _login() async {
    final ok = await ensureLoggedIn(context);
    if (ok && mounted) {
      context.read<CartProvider>().loadCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();

    if (auth.status != AuthStatus.authenticated) {
      return Scaffold(
        appBar: GradientAppBar(
            title: Text(locale.t('cart_title')), centerTitle: true),
        body: IllustratedEmptyState(
          image: EmptyIllustrations.cart,
          title: locale.t('cart_empty'),
          description: locale.t('cart_login_hint'),
          actionButton: GuestLoginButton(
            label: locale.t('login_button'),
            onPressed: _login,
          ),
        ),
      );
    }

    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: GradientAppBar(
          title: Text(locale.t('cart_title')), centerTitle: true),
      body: cart.isLoading && cart.items.isEmpty
          ? const _CartSkeleton()
          : cart.items.isEmpty
              ? IllustratedEmptyState(
                  image: EmptyIllustrations.cart,
                  title: locale.t('cart_empty'),
                  description: locale.t('empty_cart_body'),
                )
              : RefreshIndicator(
                  onRefresh: cart.loadCart,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _CartItemCard(
                      key: ValueKey(cart.items[index].id),
                      cartItem: cart.items[index],
                      cart: cart,
                      locale: locale,
                    ),
                  ),
                ),
      bottomNavigationBar: cart.items.isEmpty ? null : _summary(cart, locale),
    );
  }

  /// Нижняя панель: купон (раскрывается), итог и кнопка оформления.
  Widget _summary(CartProvider cart, LocaleProvider locale) {
    final canCheckout = cart.selectedIds.isNotEmpty;
    final couponApplied = cart.appliedCouponCode != null;
    final open = _couponOpen || couponApplied;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: AppColors.isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: AppColors.subtle,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // --- купон ---
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _couponOpen = !_couponOpen),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: HugeIcon(
                            icon: HugeIcons.strokeRoundedDiscount,
                            size: 18,
                            color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        couponApplied
                            ? '${locale.t('coupon_applied')} · ${cart.appliedCouponCode}'
                            : locale.t('promo_code'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: couponApplied
                              ? AppColors.success
                              : AppColors.headingText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: AppMotion.duration(context, AppMotion.standard),
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowDown01,
                          size: 20,
                          color: AppColors.bodyText),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: AppMotion.duration(context, AppMotion.standard),
                curve: AppMotion.easeOut,
                alignment: Alignment.topCenter,
                child: open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _applyCoupon(),
                                decoration: InputDecoration(
                                  hintText: locale.t('promo_code'),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed:
                                    _applyingCoupon ? null : _applyCoupon,
                                child: _applyingCoupon
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : Text(locale.t('apply')),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.subtle),
              ),
              // --- итог ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(locale.t('total'),
                      style: TextStyle(
                          color: AppColors.bodyText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    '${cart.total} ТМТ',
                    style: TextStyle(
                        color: AppColors.headingText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // --- оформить ---
              _CheckoutButton(
                label: '${locale.t('checkout')} (${cart.selectedIds.length})',
                enabled: canCheckout,
                onTap: _goToCheckout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Круглая отметка вместо стандартного Checkbox — в цвет бренда.
class _RoundCheck extends StatelessWidget {
  const _RoundCheck({required this.selected, this.onPhoto = false});

  final bool selected;

  /// На фото кружок белеет и получает тень, чтобы читаться на любом снимке.
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.fast),
      curve: AppMotion.easeOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppColors.accent
            : (onPhoto ? Colors.white.withValues(alpha: 0.92) : null),
        border: selected
            ? Border.all(color: Colors.white, width: onPhoto ? 1.5 : 0)
            : Border.all(
                color: AppColors.bodyText.withValues(alpha: 0.5), width: 1.6),
        boxShadow: onPhoto
            ? const [BoxShadow(color: Color(0x33000000), blurRadius: 6)]
            : null,
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: Curves.easeOutBack,
        child: const Center(
          child: HugeIcon(
              icon: HugeIcons.strokeRoundedTick02,
              size: 14,
              color: Colors.white,
              strokeWidth: 2.6),
        ),
      ),
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  const _CheckoutButton(
      {required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: AppMotion.duration(context, AppMotion.standard),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.softGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.gradientEnd.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onTap : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 20,
                    color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard(
      {super.key,
      required this.cartItem,
      required this.cart,
      required this.locale});

  final CartItem cartItem;
  final CartProvider cart;
  final LocaleProvider locale;

  static const _photoWidth = 104.0;
  static const _photoHeight = 124.0;

  @override
  Widget build(BuildContext context) {
    final selected = cart.selectedIds.contains(cartItem.id);
    final variants = [
      if (cartItem.selectSize != null)
        '${locale.t('size')}: ${cartItem.selectSize}',
      if (cartItem.selectColor != null)
        '${locale.t('color')}: ${cartItem.selectColor}',
    ];
    final total = cartItem.totalPrice;
    final unit = total != null && cartItem.quantity > 1
        ? (total / cartItem.quantity).round()
        : null;

    void openProduct() => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(slug: cartItem.item.slug)),
        );

    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.standard),
      curve: AppMotion.easeOut,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.subtle,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientEnd
                .withValues(alpha: AppColors.isDark ? 0.0 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фото; отметка для оформления лежит на его углу.
          GestureDetector(
            onTap: openProduct,
            child: SizedBox(
              width: _photoWidth,
              height: _photoHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0.55,
                      duration: AppMotion.duration(context, AppMotion.fast),
                      child: cartItem.item.image != null
                          ? AppNetworkImage(
                              url: cartItem.item.image,
                              fit: BoxFit.cover,
                              alignment: Alignment.bottomCenter,
                              brandLoading: true,
                            )
                          : ColoredBox(color: AppColors.subtle),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => cart.toggleSelected(cartItem.id),
                      // Увеличенная зона нажатия вокруг маленькой отметки.
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _RoundCheck(selected: selected, onPhoto: true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: _photoHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: openProduct,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              cartItem.item.titleFor(locale.language),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                color: AppColors.headingText,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                height: 1.22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Удаление: небольшая красноватая плитка.
                      Tooltip(
                        message: locale.t('delete'),
                        child: Material(
                          color: AppColors.danger.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(11),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => cart.removeItem(cartItem.id),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedDelete02,
                                  size: 17,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (variants.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final v in variants) _VariantChip(text: v)
                      ],
                    ),
                  ],
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Цена за штуку, если штук больше одной.
                            if (unit != null)
                              Text(
                                '$unit ТМТ × ${cartItem.quantity}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    color: AppColors.bodyText,
                                    fontSize: 11.5),
                              ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${cartItem.totalPrice ?? '-'} ТМТ',
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _QuantityStepper(
                          cartItem: cartItem, cart: cart, locale: locale),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Заглушка загрузки корзины: три карточки той же формы, что и настоящие.
class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.subtle),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 104, height: 124, radius: 16),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 110, height: 14),
                    SizedBox(height: 14),
                    SkeletonBox(width: 80, height: 22, radius: 8),
                    SizedBox(height: 34),
                    SkeletonBox(width: 90, height: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            color: AppColors.bodyText,
            fontSize: 11.5,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper(
      {required this.cartItem, required this.cart, required this.locale});

  final CartItem cartItem;
  final CartProvider cart;
  final LocaleProvider locale;

  @override
  Widget build(BuildContext context) {
    final canDecrease = cartItem.quantity > 1;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            tooltip: locale.t('decrease'),
            icon: HugeIcons.strokeRoundedMinusSign,
            onTap: canDecrease
                ? () => cart.updateQuantity(cartItem.id, cartItem.quantity - 1)
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${cartItem.quantity}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.headingText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
          ),
          _StepButton(
            tooltip: locale.t('increase'),
            icon: HugeIcons.strokeRoundedAdd01,
            onTap: () =>
                cart.updateQuantity(cartItem.id, cartItem.quantity + 1),
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton(
      {required this.tooltip,
      required this.icon,
      required this.onTap,
      this.filled = false});

  final String tooltip;
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.35,
          duration: AppMotion.duration(context, AppMotion.fast),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: filled ? AppColors.softGradient : null,
              color: filled ? null : AppColors.card,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                size: 16,
                color: filled ? Colors.white : AppColors.headingText,
                strokeWidth: 2.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
