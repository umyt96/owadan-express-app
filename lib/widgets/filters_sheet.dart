import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/filter_option.dart';
import '../providers/locale_provider.dart';
import '../services/catalog_service.dart';
import '../theme/app_theme.dart';
import 'skeleton.dart';

class ProductFilters {
  final int? colorId;
  final String? colorTitle;
  final int? sizeId;
  final String? sizeTitle;
  final int? minPrice;
  final int? maxPrice;
  final bool inStockOnly;

  const ProductFilters({
    this.colorId,
    this.colorTitle,
    this.sizeId,
    this.sizeTitle,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
  });

  bool get isEmpty =>
      colorId == null && sizeId == null && minPrice == null && maxPrice == null && !inStockOnly;
}

/// Панель фильтров — цвет, размер, диапазон цены (минимальная/максимальная).
/// Фильтр по категории на этом экране не нужен отдельно: пользователь уже
/// либо внутри категории (ProductListScreen открыт с categorySlug), либо
/// выбирает категорию через каталог/поиск до этого экрана.
///
/// ВАЖНО: цвет и размер подгружаются с /colors/ и /sizes/ — предполагаю,
/// что в вашем REST API такие эндпоинты есть (по аналогии с /brands/). Если
/// их нет, эти секции просто не покажутся, остальное продолжит работать.
Future<ProductFilters?> showFiltersSheet(
  BuildContext context, {
  required ProductFilters current,
  bool showInStock = true,
}) {
  return showModalBottomSheet<ProductFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _FiltersSheetContent(current: current, showInStock: showInStock),
  );
}

class _FiltersSheetContent extends StatefulWidget {
  final ProductFilters current;
  final bool showInStock;

  const _FiltersSheetContent({required this.current, this.showInStock = true});

  @override
  State<_FiltersSheetContent> createState() => _FiltersSheetContentState();
}

class _FiltersSheetContentState extends State<_FiltersSheetContent> {
  final _catalogService = CatalogService();
  late Future<List<FilterOption>> _colorsFuture;
  late Future<List<FilterOption>> _sizesFuture;

  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  int? _colorId;
  String? _colorTitle;
  int? _sizeId;
  String? _sizeTitle;
  bool _inStock = false;

  @override
  void initState() {
    super.initState();
    _colorsFuture = _catalogService.getColors();
    _sizesFuture = _catalogService.getSizes();
    _colorId = widget.current.colorId;
    _colorTitle = widget.current.colorTitle;
    _sizeId = widget.current.sizeId;
    _sizeTitle = widget.current.sizeTitle;
    _inStock = widget.current.inStockOnly;
    _minController = TextEditingController(text: widget.current.minPrice?.toString() ?? '');
    _maxController = TextEditingController(text: widget.current.maxPrice?.toString() ?? '');
    // Счётчик на кнопке и кнопка "Сбросить" следят за полями цены.
    _minController.addListener(_refresh);
    _maxController.addListener(_refresh);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  /// Сколько фильтров выбрано: цена считается одним (от и/или до).
  int get _activeCount =>
      (_colorId != null ? 1 : 0) +
      (_sizeId != null ? 1 : 0) +
      (_inStock ? 1 : 0) +
      (_minController.text.trim().isNotEmpty || _maxController.text.trim().isNotEmpty ? 1 : 0);

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _colorId = null;
      _colorTitle = null;
      _sizeId = null;
      _sizeTitle = null;
      _inStock = false;
      _minController.clear();
      _maxController.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      ProductFilters(
        colorId: _colorId,
        colorTitle: _colorTitle,
        sizeId: _sizeId,
        sizeTitle: _sizeTitle,
        minPrice: int.tryParse(_minController.text.trim()),
        maxPrice: int.tryParse(_maxController.text.trim()),
        inStockOnly: _inStock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final count = _activeCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // --- Ручка и шапка ---
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.subtle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 8),
              child: Row(
                children: [
                  _SectionIcon(icon: HugeIcons.strokeRoundedFilterHorizontal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      locale.t('filters'),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        color: AppColors.headingText,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // "Сбросить" проявляется, только когда есть что сбрасывать.
                  AnimatedOpacity(
                    opacity: count > 0 ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(
                      ignoring: count == 0,
                      child: TextButton(
                        onPressed: _reset,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: AppColors.accent.withOpacity(0.10),
                        ),
                        child: Text(
                          locale.t('reset'),
                          style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // --- Разделы ---
            Expanded(
              child: ListView(
                controller: scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  // Только товары «в наличии» (галочка у товара «Есть в наличии»).
                  if (widget.showInStock) ...[
                  Material(
                    color: _inStock ? AppColors.accent.withValues(alpha: 0.10) : AppColors.subtle.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    child: CheckboxListTile(
                      value: _inStock,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _inStock = v ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        locale.t('filter_in_stock'),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.headingText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ],
                  _SectionTitle(locale.t('price_range')),
                  Row(
                    children: [
                      Expanded(
                        child: _PriceField(controller: _minController, label: locale.t('price_from')),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: 12,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.bodyText.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _PriceField(controller: _maxController, label: locale.t('price_to')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _OptionsSection(
                    title: locale.t('color'),
                    future: _colorsFuture,
                    selectedId: _colorId,
                    onSelect: (option) => setState(() {
                      _colorId = option?.id;
                      _colorTitle = option?.title;
                    }),
                  ),
                  _OptionsSection(
                    title: locale.t('size'),
                    future: _sizesFuture,
                    selectedId: _sizeId,
                    onSelect: (option) => setState(() {
                      _sizeId = option?.id;
                      _sizeTitle = option?.title;
                    }),
                  ),
                ],
              ),
            ),
            // --- Кнопка применения закреплена внизу ---
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + inset + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.subtle)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        locale.t('apply'),
                        style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      // Число выбранных фильтров на кнопке.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: count == 0
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Container(
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.24),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final List<List<dynamic>> icon;

  const _SectionIcon({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(child: HugeIcon(icon: icon, color: AppColors.accent, size: 21)),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Gilroy',
            color: AppColors.headingText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

/// Поле цены: заполненная плитка без рамки, подпись внутри, "TMT" справа.
class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PriceField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      cursorColor: AppColors.accent,
      style: TextStyle(
        fontFamily: 'Gilroy',
        color: AppColors.headingText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 14),
        floatingLabelStyle: const TextStyle(fontFamily: 'Gilroy', color: AppColors.accent, fontWeight: FontWeight.w700),
        suffixText: 'TMT',
        suffixStyle: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: AppColors.subtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
      ),
    );
  }
}

/// Раздел с выбором одного варианта (цвет, размер). Пока варианты грузятся —
/// заглушки-плашки; если их нет вовсе — раздел не показывается.
class _OptionsSection extends StatelessWidget {
  final String title;
  final Future<List<FilterOption>> future;
  final int? selectedId;
  final ValueChanged<FilterOption?> onSelect;

  const _OptionsSection({
    required this.title,
    required this.future,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FilterOption>>(
      future: future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final options = snapshot.data ?? [];
        if (!loading && options.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title),
              if (loading)
                const SkeletonPulse(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SkeletonBox(width: 72, height: 38, radius: 13),
                      SkeletonBox(width: 88, height: 38, radius: 13),
                      SkeletonBox(width: 64, height: 38, radius: 13),
                      SkeletonBox(width: 80, height: 38, radius: 13),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in options)
                      _OptionChip(
                        label: option.title,
                        selected: selectedId == option.id,
                        // Повторное нажатие снимает выбор.
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelect(selectedId == option.id ? null : option);
                        },
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Плашка варианта: выбранная заливается акцентом и получает галочку.
class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(selected ? 12 : 16, 9, 16, 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.subtle,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.accent.withOpacity(0.30), blurRadius: 10, offset: const Offset(0, 4))]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: duration,
                curve: Curves.easeOutCubic,
                child: selected
                    ? const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: HugeIcon(icon: HugeIcons.strokeRoundedTick02, color: Colors.white, size: 16),
                      )
                    : const SizedBox.shrink(),
              ),
              AnimatedDefaultTextStyle(
                duration: duration,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.headingText,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
