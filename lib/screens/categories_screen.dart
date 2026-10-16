import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/locale_provider.dart';
import '../services/catalog_service.dart';
import 'subcategories_screen.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/illustrated_empty_state.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  /// Выбранный вид живёт дольше экрана — вкладка пересоздаётся при обновлении.
  static bool _gridView = true;

  final _catalogService = CatalogService();
  final _scroll = ScrollController();
  late Future<List<AllCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = _catalogService.getAllCategories();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(locale.t('categories_title')),
        actions: [
          IconButton(
            tooltip:
                locale.t(_gridView ? 'view_as_list' : 'view_as_grid'),
            onPressed: () => setState(() => _gridView = !_gridView),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween(begin: 0.85, end: 1.0).animate(animation),
                child: ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
              ),
              // Показываем вид, на который переключит нажатие.
              child: HugeIcon(
                key: ValueKey(_gridView),
                icon: _gridView
                    ? HugeIcons.strokeRoundedLeftToRightListBullet
                    : HugeIcons.strokeRoundedGridView,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final future = _catalogService.getAllCategories();
          setState(() {
            _future = future;
          });
          await future;
        },
        child: FutureBuilder<List<AllCategory>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                const SizedBox(height: 120),
                Center(child: Text('${locale.t('error')}: ${snapshot.error}')),
              ]);
            }
            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return IllustratedEmptyState(
                image: EmptyIllustrations.catalog,
                title: locale.t('empty_categories_title'),
                description: locale.t('empty_categories_body'),
              );
            }
            void openCategory(AllCategory category) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubCategoriesScreen(
                    parentSlug: category.slug,
                    parentTitle: category.titleFor(locale.language),
                  ),
                ),
              );
            }

            Widget enter(int index, Widget child) =>
                // Карточки въезжают снизу с небольшой задержкой по порядку.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 320 + (index % 8) * 60),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - t)),
                      child: child,
                    ),
                  ),
                  child: child,
                );

            final Widget content = _gridView
                ? GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return enter(
                        index,
                        _CategoryCard(
                          title: category.titleFor(locale.language),
                          image: category.image,
                          variant: index,
                          onTap: () => openCategory(category),
                        ),
                      );
                    },
                  )
                : ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return enter(
                        index,
                        _CategoryListTile(
                          scrollController: _scroll,
                          title: category.titleFor(locale.language),
                          image: category.image,
                          variant: index,
                          onTap: () => openCategory(category),
                        ),
                      );
                    },
                  );

            // Плавная смена вида: старый список растворяется, новый проявляется.
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_gridView),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Категория строкой, как в food_delivery: широкая фото-карточка, название
/// поверх тёмной подложки внизу, цветное свечение вместо серой тени. Фото
/// чуть "плывёт" против прокрутки (параллакс).
class _CategoryListTile extends StatefulWidget {
  final ScrollController scrollController;
  final String title;
  final String? image;
  final int variant;
  final VoidCallback onTap;

  const _CategoryListTile({
    required this.scrollController,
    required this.title,
    required this.image,
    required this.variant,
    required this.onTap,
  });

  @override
  State<_CategoryListTile> createState() => _CategoryListTileState();
}

class _CategoryListTileState extends State<_CategoryListTile> {
  bool _pressed = false;

  static const _radius = 28.0;
  static const _bleed = 56.0;

  @override
  Widget build(BuildContext context) {
    final colors = _CategoryCardState
        ._fallbacks[widget.variant % _CategoryCardState._fallbacks.length];
    final tint = colors.first;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            // Цветное свечение — выглядит как глубина, а не серая тень.
            BoxShadow(
              color: tint.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: tint,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: SizedBox(
              height: 210,
              child: _ScrollDrift(
                controller: widget.scrollController,
                range: 48,
                builder: (context, shift) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: -_bleed,
                      bottom: -_bleed,
                      left: 0,
                      right: 0,
                      // Фото передаётся как child: строится один раз, при
                      // прокрутке пересчитывается только сдвиг.
                      child: ValueListenableBuilder<double>(
                        valueListenable: shift,
                        child: _CategoryImage(
                            image: widget.image, colors: colors),
                        builder: (context, value, child) =>
                            Transform.translate(
                          offset: Offset(0, value),
                          child: child,
                        ),
                      ),
                    ),
                    // Подложка снизу вверх, чтобы название читалось на любом фото.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Color(0xB3000000),
                          ],
                          stops: [0.0, 0.25, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28)),
                            ),
                            child: const Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowRight01,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Следит, насколько блок смещён от центра экрана, и публикует сдвиг в пикселях
/// как [ValueListenable] — общая основа параллакса. Значение не хранится в
/// State: setState на каждый тик прокрутки перестраивал бы всё поддерево
/// карточки (фото, подложку, подписи), а так перестраивается только слой
/// Transform.
class _ScrollDrift extends StatefulWidget {
  const _ScrollDrift({
    required this.controller,
    required this.range,
    required this.builder,
  });

  final ScrollController controller;
  final double range;
  final Widget Function(BuildContext context, ValueListenable<double> shift)
      builder;

  @override
  State<_ScrollDrift> createState() => _ScrollDriftState();
}

class _ScrollDriftState extends State<_ScrollDrift> {
  final _key = GlobalKey();
  final _shift = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    _shift.dispose();
    super.dispose();
  }

  void _update() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !mounted) return;
    final viewport = MediaQuery.sizeOf(context).height;
    final centerY = box.localToGlobal(Offset.zero).dy + box.size.height / 2;
    final fraction = ((centerY - viewport / 2) / viewport).clamp(-0.6, 0.6);
    final next = fraction * widget.range;
    // Сдвиг меньше пикселя не виден — не перерисовываем на каждый тик.
    if ((next - _shift.value).abs() > 0.4) _shift.value = next;
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.builder(context, _shift));
  }
}

/// Карточка категории: фото на всю карточку, фирменная тёмная подложка
/// снизу и название поверх. При нажатии слегка уменьшается.
class _CategoryCard extends StatefulWidget {
  final String title;
  final String? image;
  final int variant;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.image,
    required this.variant,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  static const _fallbacks = [
    [AppColors.gradientEnd],
    [Color(0xFF942080)],
    [Color(0xFF5F257E)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _fallbacks[widget.variant % _fallbacks.length];

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientEnd.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: colors.last,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CategoryImage(image: widget.image, colors: colors),
                // Подложка под текст: от прозрачного к фирменному фиолетовому.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00481173),
                        Color(0x66481173),
                        Color(0xF2481173),
                      ],
                      stops: [0.35, 0.65, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28)),
                    ),
                    child: const Icon(Icons.arrow_outward_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1.12,
                        ),
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

class _CategoryImage extends StatelessWidget {
  final String? image;
  final List<Color> colors;

  const _CategoryImage({required this.image, required this.colors});

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: colors.first,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Icon(
            Icons.category_outlined,
            size: 54,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );

    if (image == null || image!.isEmpty) return fallback;
    return Image.network(
      image!,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, sync) => Stack(
        fit: StackFit.expand,
        children: [
          fallback,
          AnimatedOpacity(
            opacity: frame == null && !sync ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: child,
          ),
        ],
      ),
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
