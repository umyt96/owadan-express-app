import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../utils/image_preload.dart';
import '../widgets/appear_in_turn.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/locale_provider.dart';
import '../services/catalog_service.dart';
import '../services/analytics_service.dart';
import '../widgets/bar_button.dart';
import '../widgets/product_card.dart';
import '../widgets/search_results_layer.dart';
import '../widgets/search_title.dart';
import '../widgets/skeleton.dart';
import 'product_list_screen.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/illustrated_empty_state.dart';
import '../theme/app_theme.dart';

class SubCategoriesScreen extends StatefulWidget {
  final String parentSlug;
  final String parentTitle;

  const SubCategoriesScreen({
    super.key,
    required this.parentSlug,
    required this.parentTitle,
  });

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  final _catalogService = CatalogService();
  late Future<List<ProductCategory>> _subcategoriesFuture;

  final List<ItemSummary> _items = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  // Поиск внутри категории: поле вырастает из кнопки в панели, а результаты
  // поднимаются снизу отдельным слоем поверх страницы.
  bool _searchOpen = false;
  String _search = '';
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;

  final List<ItemSummary> _searchItems = [];
  int _searchPage = 1;
  bool _searchLoading = false;
  bool _searchHasMore = true;

  /// Номер последнего поискового запроса: ответ на устаревший (до смены
  /// строки поиска) отбрасывается, чтобы не подмешать чужие товары.
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _subcategoriesFuture =
        _catalogService.getSubCategories(parentSlug: widget.parentSlug);
    _loadItemsPage(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Товары самой категории (и всех её подкатегорий) — как на сайте, где на
  // странице категории показываются и подкатегории, и товары под ними сразу.
  Future<void> _loadItemsPage({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _items.clear();
      }
    });
    try {
      final result = await _catalogService.getItems(
        parentCategorySlug: widget.parentSlug,
        page: _page,
      );
      if (!mounted) return;
      await precacheItemImages(context, result.results);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.results);
        _hasMore = result.next != null;
        _page++;
      });
    } catch (_) {
      if (mounted) setState(() => _hasMore = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSearchPage({bool reset = false}) async {
    if (_search.isEmpty) return;
    if (_searchLoading && !reset) return;
    final id = reset ? ++_searchRequestId : _searchRequestId;
    setState(() {
      _searchLoading = true;
      if (reset) {
        _searchPage = 1;
        _searchHasMore = true;
        _searchItems.clear();
      }
    });
    try {
      final result = await _catalogService.getItems(
        parentCategorySlug: widget.parentSlug,
        search: _search,
        page: _searchPage,
      );
      if (!mounted || id != _searchRequestId) return;
      await precacheItemImages(context, result.results);
      if (!mounted || id != _searchRequestId) return;
      setState(() {
        _searchItems.addAll(result.results);
        _searchHasMore = result.next != null;
        _searchPage++;
      });
    } catch (_) {
      if (mounted && id == _searchRequestId)
        setState(() => _searchHasMore = false);
    } finally {
      if (mounted && id == _searchRequestId)
        setState(() => _searchLoading = false);
    }
  }

  void _toggleSearch() {
    if (_searchOpen) {
      _closeSearch();
      return;
    }
    // Каждое открытие начинается с чистого листа; прошлые результаты не
    // стираются при закрытии, чтобы слой не мигал, пока опускается.
    _searchRequestId++;
    setState(() {
      _search = '';
      _searchItems.clear();
      _searchLoading = false;
      _searchHasMore = true;
      _searchOpen = true;
    });
    // Фокус — когда капсула уже раскрылась, иначе клавиатура дёргает кадр.
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted && _searchOpen) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchDebounce?.cancel();
    _searchFocus.unfocus();
    _searchController.clear();
    setState(() => _searchOpen = false);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 400), () => _applySearch(value));
  }

  void _applySearch(String value) {
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    if (!mounted || trimmed == _search) return;
    if (trimmed.isEmpty) {
      _searchRequestId++;
      setState(() {
        _search = '';
        _searchItems.clear();
        _searchLoading = false;
      });
      return;
    }
    AnalyticsService.instance.event('search', data: {'query': trimmed});
    setState(() => _search = trimmed);
    _loadSearchPage(reset: true);
  }

  /// Содержимое поднимающегося слоя: подсказка, заглушки, результаты или
  /// "ничего не найдено".
  Widget _buildSearchBody(LocaleProvider locale) {
    if (_search.isEmpty) {
      return IllustratedEmptyState(
        image: EmptyIllustrations.catalog,
        title: locale.t('search_hint'),
        description: locale.t('search_prompt'),
      );
    }
    if (_searchLoading && _searchItems.isEmpty) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: ProductGridSkeleton(),
      );
    }
    if (_searchItems.isEmpty) {
      return IllustratedEmptyState(
        image: EmptyIllustrations.catalog,
        title: locale.t('nothing_found'),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) _searchFocus.unfocus();
        if (_searchHasMore &&
            !_searchLoading &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          _loadSearchPage();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => AppearInTurn(
                  id: _searchItems[index].id,
                  index: index,
                  child: ProductCard(item: _searchItems[index]),
                ),
                childCount: _searchItems.length,
              ),
            ),
          ),
          if (_searchLoading)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(8, 12, 8, 0),
              sliver: SliverToBoxAdapter(child: ProductGridSkeleton(count: 2)),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return PopScope(
      // Назад сначала закрывает поиск и только потом покидает экран.
      canPop: !_searchOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _searchOpen) _closeSearch();
      },
      child: Scaffold(
        appBar: GradientAppBar(
          // Пока поле открыто, кнопка "назад" уступает место, чтобы оно
          // могло занять всю ширину.
          centerTitle: !_searchOpen,
          leadingWidth: _searchOpen ? 12 : null,
          leading: _searchOpen ? const SizedBox.shrink() : null,
          title: SearchTitle(
            title: widget.parentTitle,
            open: _searchOpen,
            controller: _searchController,
            focusNode: _searchFocus,
            hint: locale.t('search_hint'),
            onChanged: _onSearchChanged,
            onSubmitted: _applySearch,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: BarButton(
                tooltip: locale.t('search'),
                icon: _searchOpen
                    ? HugeIcons.strokeRoundedCancel01
                    : HugeIcons.strokeRoundedSearch01,
                onTap: _toggleSearch,
              ),
            ),
          ],
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 1),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _subcategoriesFuture = _catalogService.getSubCategories(
                      parentSlug: widget.parentSlug);
                });
                await Future.wait(
                    [_subcategoriesFuture, _loadItemsPage(reset: true)]);
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (_hasMore &&
                      !_isLoading &&
                      notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 200) {
                    _loadItemsPage();
                  }
                  return false;
                },
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    // --- Подкатегории ---
                    SliverToBoxAdapter(
                      child: FutureBuilder<List<ProductCategory>>(
                        future: _subcategoriesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SubCategoriesSkeleton();
                          }
                          final subcategories = snapshot.data ?? [];
                          if (subcategories.isEmpty)
                            return const SizedBox.shrink();
                          // Равные плитки в два ряда: шесть подкатегорий ровно
                          // занимают экран, больше — прокрутка вбок. Читается как
                          // обычный текст: первый ряд слева направо, потом второй.
                          final columns = (subcategories.length + 1) ~/ 2;
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = 8.0;
                              final tileWidth =
                                  (constraints.maxWidth - 32 - gap * 2) / 3;

                              Widget tile(ProductCategory sub) {
                                final subTitle = sub.titleFor(locale.language);
                                return SizedBox(
                                  width: tileWidth,
                                  child: _SubCategoryChip(
                                    title: subTitle,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ProductListScreen(
                                            title: subTitle,
                                            categorySlug: sub.slug,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var c = 0; c < columns; c++) ...[
                                      if (c > 0) const SizedBox(width: gap),
                                      Column(
                                        children: [
                                          tile(subcategories[c]),
                                          if (c + columns <
                                              subcategories.length) ...[
                                            const SizedBox(height: gap),
                                            tile(subcategories[c + columns]),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // --- Товары категории ---
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      sliver: _items.isEmpty
                          ? SliverToBoxAdapter(
                              child: _isLoading
                                  ? const ProductGridSkeleton()
                                  : Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 20, 12, 40),
                                      child: Column(
                                        children: [
                                          Image.asset(
                                              EmptyIllustrations.catalog,
                                              width: 180,
                                              height: 180,
                                              excludeFromSemantics: true),
                                          Text(locale.t('no_products_yet'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: AppColors.headingText,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                            )
                          : SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.62,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => AppearInTurn(
                                  id: _items[index].id,
                                  index: index,
                                  child: ProductCard(item: _items[index]),
                                ),
                                childCount: _items.length,
                              ),
                            ),
                    ),
                    // Следующая страница: пара заглушек под последними товарами.
                    if (_isLoading && _items.isNotEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ),
            // Результаты поиска поднимаются снизу поверх страницы.
            Positioned.fill(
              child: SearchResultsLayer(
                open: _searchOpen,
                child: _buildSearchBody(locale),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Подкатегория — только название, ровной плиткой с мягкой акцентной заливкой.
/// При нажатии слегка уменьшается.
class _SubCategoryChip extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _SubCategoryChip({required this.title, required this.onTap});

  @override
  State<_SubCategoryChip> createState() => _SubCategoryChipState();
}

class _SubCategoryChipState extends State<_SubCategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color:
            AppColors.accent.withValues(alpha: AppColors.isDark ? 0.16 : 0.08),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.20)),
        ),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: SizedBox(
            height: 42,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: AppColors.brand,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
