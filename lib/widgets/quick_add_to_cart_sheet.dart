import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../services/catalog_service.dart';
import '../theme/app_theme.dart';
import '../utils/auth_guard.dart';
import 'cart_fly_animation.dart';
import 'gradient_app_bar.dart';
import 'product_detail_widgets.dart';
import 'skeleton.dart';

/// Открывается при нажатии на кнопку корзины прямо в списке товаров (не заходя
/// на страницу товара) — показывает фото, цвета и размеры, и требует их
/// выбрать, если они у товара есть, прежде чем добавить в корзину.
Future<void> showQuickAddToCartSheet(BuildContext context, String slug) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _QuickAddToCartSheet(slug: slug),
  );
}

class _QuickAddToCartSheet extends StatefulWidget {
  final String slug;

  const _QuickAddToCartSheet({required this.slug});

  @override
  State<_QuickAddToCartSheet> createState() => _QuickAddToCartSheetState();
}

class _QuickAddToCartSheetState extends State<_QuickAddToCartSheet> {
  final _catalogService = CatalogService();
  late Future<ItemDetail> _future;
  ItemSize? _selectedSize;
  ItemColor? _selectedColor;
  int _quantity = 1;
  bool _adding = false;

  /// Метка кнопки: из её центра вылетает фото товара.
  final _addKey = GlobalKey();

  /// Не выбрали обязательное — подсвечиваем раздел вместо всплывающей надписи.
  bool _sizeMissing = false;
  bool _colorMissing = false;

  @override
  void initState() {
    super.initState();
    _future = _catalogService.getItem(widget.slug);
  }

  Future<void> _add(ItemDetail item) async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    final locale = context.read<LocaleProvider>();
    final needSize = item.sizes.isNotEmpty && _selectedSize == null;
    final needColor = item.colors.isNotEmpty && _selectedColor == null;
    if (needSize || needColor) {
      HapticFeedback.mediumImpact();
      setState(() {
        _sizeMissing = needSize;
        _colorMissing = needColor;
      });
      return;
    }
    setState(() => _adding = true);
    final ok = await context.read<CartProvider>().addToCart(
          item.slug,
          quantity: _quantity,
          size: _selectedSize?.title,
          color: _selectedColor?.title,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? locale.t('added_to_cart') : locale.t('error'))),
    );
    if (ok) {
      HapticFeedback.lightImpact();
      // Фото летит к значку корзины в нижнем меню и переживает закрытие шторки.
      CartFlyAnimation.runFromKey(fromKey: _addKey, image: item.image);
      Navigator.of(context).pop();
      return;
    }
    setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ручка шторки.
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.subtle, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Flexible(
              child: FutureBuilder<ItemDetail>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _SheetSkeleton();
                  }
                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 140,
                      child: Center(child: Text('${locale.t('error')}: ${snapshot.error}')),
                    );
                  }
                  return _buildContent(snapshot.data!, locale);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ItemDetail item, LocaleProvider locale) {
    final unit = item.displayPriceFor(_selectedSize);
    final listPrice = item.priceFor(_selectedSize);
    final hasOld = item.discountPriceFor(_selectedSize) != null &&
        listPrice != null &&
        item.discountPriceFor(_selectedSize) != listPrice;
    final total = unit == null ? null : unit * _quantity;
    final inStock = item.quantity >= 1;

    final sizeIndex = _selectedSize == null ? null : item.sizes.indexWhere((e) => e.id == _selectedSize!.id);
    final colorIndex = _selectedColor == null ? null : item.colors.indexWhere((e) => e.id == _selectedColor!.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Шапка: фото, название, цена, закрыть ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: item.image != null
                            ? AppNetworkImage(
                                url: item.image,
                                fit: BoxFit.cover,
                                alignment: Alignment.bottomCenter,
                                brandLoading: true,
                              )
                            : ColoredBox(color: AppColors.subtle),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.titleFor(locale.language),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              color: AppColors.headingText,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(opacity: animation, child: child),
                                child: Text(
                                  '${unit ?? '-'}',
                                  key: ValueKey(unit),
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    color: AppColors.accent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                'TMT',
                                style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                              if (hasOld) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '$listPrice',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    color: AppColors.bodyText,
                                    fontSize: 13,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: AppColors.subtle, shape: BoxShape.circle),
                        child: Center(
                          child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01, size: 18, color: AppColors.headingText),
                        ),
                      ),
                    ),
                  ],
                ),
                // --- Размер ---
                if (item.sizes.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionLabel(
                    title: locale.t('size'),
                    error: _sizeMissing ? locale.t('select_size_required') : null,
                  ),
                  DetailChipPicker(
                    labels: [for (final s in item.sizes) s.label],
                    selected: sizeIndex,
                    onSelected: (i) => setState(() {
                      _selectedSize = item.sizes[i];
                      _sizeMissing = false;
                    }),
                  ),
                ],
                // --- Цвет ---
                if (item.colors.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionLabel(
                    title: locale.t('color'),
                    value: _selectedColor?.title,
                    error: _colorMissing ? locale.t('select_color_required') : null,
                  ),
                  // Цвет — текстом, как размеры (без фото цвета).
                  DetailChipPicker(
                    labels: [for (final c in item.colors) c.title],
                    selected: colorIndex,
                    onSelected: (i) => setState(() {
                      _selectedColor = item.colors[i];
                      _colorMissing = false;
                    }),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        // --- Нижняя панель: количество и кнопка с итогом ---
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + MediaQuery.paddingOf(context).bottom * 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.subtle)),
          ),
          child: Row(
            children: [
              _QuantityPill(
                value: _quantity,
                onMinus: _quantity > 1 ? () => setState(() => _quantity--) : null,
                onPlus: () => setState(() => _quantity++),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AddButton(
                  key: _addKey,
                  label: inStock ? locale.t('add_to_cart') : locale.t('out_of_stock'),
                  total: inStock ? total : null,
                  enabled: inStock,
                  busy: _adding,
                  onTap: () => _add(item),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Заголовок раздела выбора; если выбор обязателен и не сделан — краснеет и
/// показывает подсказку.
class _SectionLabel extends StatelessWidget {
  final String title;
  final String? value;
  final String? error;

  const _SectionLabel({required this.title, this.value, this.error});

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: hasError ? AppColors.danger : AppColors.headingText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 14),
              ),
            ),
          ],
          if (hasError) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                error!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Gilroy', color: AppColors.danger, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Количество: серая капсула с − / + и числом.
class _QuantityPill extends StatelessWidget {
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  const _QuantityPill({required this.value, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    Widget step(List<List<dynamic>> icon, VoidCallback? onTap) => InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 52,
            child: Center(
              child: HugeIcon(
                icon: icon,
                size: 18,
                color: onTap == null ? AppColors.bodyText.withOpacity(0.4) : AppColors.headingText,
              ),
            ),
          ),
        );

    return Material(
      color: AppColors.subtle,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          step(HugeIcons.strokeRoundedMinusSign, onMinus),
          SizedBox(
            width: 26,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  color: AppColors.headingText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          step(HugeIcons.strokeRoundedAdd01, onPlus),
        ],
      ),
    );
  }
}

/// Кнопка добавления: подпись слева, справа итоговая сумма (цена × количество).
class _AddButton extends StatelessWidget {
  final String label;
  final int? total;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  const _AddButton({
    super.key,
    required this.label,
    required this.total,
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: enabled ? AppColors.accent : AppColors.subtle,
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [BoxShadow(color: AppColors.accent.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 5))]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled && !busy ? onTap : null,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                color: enabled ? Colors.white : AppColors.bodyText,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (total != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(opacity: animation, child: child),
                              child: Text(
                                '$total TMT',
                                key: ValueKey(total),
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Заглушка шторки, пока товар грузится: шапка и ряд вариантов.
class _SheetSkeleton extends StatelessWidget {
  const _SheetSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPulse(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 92, height: 92, radius: 18),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 16),
                      SizedBox(height: 8),
                      SkeletonBox(width: 120, height: 16),
                      SizedBox(height: 14),
                      SkeletonBox(width: 90, height: 24),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SkeletonBox(width: 70, height: 16),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SkeletonBox(width: 64, height: 44, radius: 14),
                SkeletonBox(width: 64, height: 44, radius: 14),
                SkeletonBox(width: 64, height: 44, radius: 14),
              ],
            ),
            SizedBox(height: 28),
            SkeletonBox(height: 52, radius: 16),
          ],
        ),
      ),
    );
  }
}
