import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../utils/image_preload.dart';
import '../widgets/appear_in_turn.dart';
import '../models/banner_item.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/locale_provider.dart';
import '../services/catalog_service.dart';
import '../widgets/bar_button.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/gradient_app_bar.dart';
import 'search_screen.dart';
import 'product_list_screen.dart';
import '../widgets/app_drawer.dart';
import 'brands_screen.dart';
import 'categories_screen.dart';
import 'subcategories_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _catalogService = CatalogService();

  late Future<List<BannerItem>> _bannersFuture;
  late Future<List<AllCategory>> _categoriesFuture;
  late Future<List<Brand>> _brandsFuture;
  late Future<List<ItemSummary>> _newItemsFuture;
  final _bannerController = PageController();
  int _bannerIndex = 0;

  // "Рекомендуемые" — случайные товары, как на сайте (order_by('?')):
  // страницы каталога берутся в случайном порядке (при каждом открытии и
  // обновлении — новый порядок), товары внутри страницы перемешиваются.
  // Лента бесконечная — подгружается по мере прокрутки.
  static const _apiPageSize = 20; // REST_FRAMEWORK PAGE_SIZE на сервере
  final _scrollController = ScrollController();
  final List<ItemSummary> _recommended = [];
  final Set<int> _recommendedIds = {};
  List<int> _recPageOrder = [];
  int _recTotalCount = 0;
  bool _recLoading = false;
  bool _recHasMore = true;

  @override
  void initState() {
    super.initState();
    _bannersFuture = _catalogService.getBanners();
    _categoriesFuture = _catalogService.getAllCategories();
    _brandsFuture = _catalogService.getBrands();
    _newItemsFuture = _loadNewItems();
    _loadMoreRecommended();
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels > pos.maxScrollExtent - 800) _loadMoreRecommended();
    });
  }

  Future<void> _loadMoreRecommended({bool reset = false}) async {
    if (_recLoading) return;
    if (!reset && !_recHasMore) return;
    setState(() {
      _recLoading = true;
      if (reset) {
        _recommended.clear();
        _recommendedIds.clear();
        _recPageOrder = [];
        _recHasMore = true;
      }
    });
    try {
      if (_recPageOrder.isEmpty && _recommended.isEmpty) {
        // Общее количество товаров знаем из запроса "Новые" (те же фильтры).
        await _newItemsFuture;
        final pages = (_recTotalCount / _apiPageSize).ceil();
        _recPageOrder = List.generate(pages < 1 ? 1 : pages, (i) => i + 1)..shuffle();
      }
      if (_recPageOrder.isEmpty) {
        if (mounted) setState(() => _recHasMore = false);
        return;
      }
      final result = await _catalogService.getItems(page: _recPageOrder.removeAt(0));
      final page = result.results.where((i) => _recommendedIds.add(i.id)).toList()..shuffle();
      if (!mounted) return;
      // Показываем товары, только когда их фото уже загружены (спиннер внизу).
      await precacheItemImages(context, page);
      if (!mounted) return;
      setState(() {
        _recommended.addAll(page);
        _recHasMore = _recPageOrder.isNotEmpty;
      });
    } catch (_) {
      if (mounted) setState(() => _recHasMore = false);
    } finally {
      if (mounted) setState(() => _recLoading = false);
    }
  }

  // "Новые" — как на сайте: сортировка по дате создания, самые новые сверху,
  // ограничено 18 товарами (как на сайте: paginate_by = 18).
  Future<List<ItemSummary>> _loadNewItems() async {
    final result = await _catalogService.getItems(ordering: '-created_date');
    _recTotalCount = result.count;
    return result.results.take(18).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _bannersFuture = _catalogService.getBanners();
      _categoriesFuture = _catalogService.getAllCategories();
      _brandsFuture = _catalogService.getBrands();
      _newItemsFuture = _loadNewItems();
      _bannerIndex = 0;
    });
    if (_bannerController.hasClients) _bannerController.jumpToPage(0);
    await Future.wait<void>([_bannersFuture, _categoriesFuture, _brandsFuture, _newItemsFuture, _loadMoreRecommended(reset: true)].map((future) async {
      try {
        await future;
      } catch (_) {}
    }));
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        centerTitle: true,
        // Меню — стеклянная кнопка того же вида, что и справа.
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Builder(
              builder: (context) => BarButton(
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                icon: HugeIcons.strokeRoundedMenu01,
                onTap: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
        ),
        // Локальный ассет: сетевой логотип пропадал и подгружался заново
        // после возврата с экрана товара.
        title: Image.asset(
          'assets/branding/splash_logo.png',
          height: 30,
        ),
        actions: [
          BarButton(
            tooltip: locale.t('search'),
            icon: HugeIcons.strokeRoundedSearch01,
            onTap: _openSearch,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FutureBuilder<List<BannerItem>>(
                future: _bannersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const BannerSkeleton();
                  }
                  final banners = (snapshot.data ?? []).where((banner) => banner.image?.isNotEmpty == true).toList();
                  if (banners.isEmpty) return const SizedBox.shrink();
                  return _BannerCarousel(
                    banners: banners,
                    controller: _bannerController,
                    currentIndex: _bannerIndex.clamp(0, banners.length - 1).toInt(),
                    onPageChanged: (index) => setState(() => _bannerIndex = index),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<AllCategory>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const StripSkeleton(height: 126, itemWidth: 116, radius: 18);
                  }
                  final categories = snapshot.data ?? [];
                  if (categories.isEmpty) return const SizedBox.shrink();
                  return _CategoryStrip(
                    categories: categories,
                    locale: locale,
                    onSeeAll: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<Brand>>(
                future: _brandsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const StripSkeleton(height: 112, itemWidth: 90, radius: 16, gap: 10);
                  }
                  final brands = snapshot.data ?? [];
                  if (brands.isEmpty) return const SizedBox.shrink();
                  return _BrandStrip(
                    brands: brands,
                    title: locale.t('drawer_brands'),
                    onSeeAll: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BrandsScreen()),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _ItemsSection(
                future: _newItemsFuture,
                title: locale.t('new_items_title'),
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductListScreen(
                      title: locale.t('new_items_title'),
                      ordering: '-created_date',
                    ),
                  ),
                ),
              ),
            ),
            if (_recommended.isNotEmpty || _recLoading)
              SliverToBoxAdapter(
                child: _SectionHeader(title: locale.t('recommended_title')),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => AppearInTurn(
                    id: _recommended[index].id,
                    index: index,
                    child: ProductCard(item: _recommended[index]),
                  ),
                  childCount: _recommended.length,
                ),
              ),
            ),
            // Загрузка рекомендаций: первая — полноценная сетка заглушек
            // с заголовком, следующие страницы — пара карточек внизу.
            if (_recLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                sliver: SliverToBoxAdapter(
                  child: _recommended.isEmpty
                      ? const ProductGridSkeleton(count: 4)
                      : const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({
    required this.banners,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<BannerItem> banners;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          SizedBox(
            height: 188,
            child: PageView.builder(
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Padding(
                  // Баннер почти во всю ширину: поля по 8, без соседних
                  // баннеров по краям.
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Material(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: AppNetworkImage(
                      url: banner.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          if (banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < banners.length; index++)
                    AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: index == currentIndex ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == currentIndex ? AppColors.accent : AppColors.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
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

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.locale,
    required this.onSeeAll,
  });

  final List<AllCategory> categories;
  final LocaleProvider locale;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          title: locale.t('categories_title'),
          onSeeAll: onSeeAll,
        ),
        SizedBox(
          height: 126,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              final title = category.titleFor(locale.language);
              return SizedBox(
                width: 116,
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 2,
                  shadowColor: AppColors.gradientEnd.withValues(alpha: 0.12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SubCategoriesScreen(
                          parentSlug: category.slug,
                          parentTitle: title,
                        ),
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(url: category.image, fit: BoxFit.cover),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.02),
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BrandStrip extends StatelessWidget {
  const _BrandStrip({
    required this.brands,
    required this.title,
    required this.onSeeAll,
  });

  final List<Brand> brands;
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(title: title, onSeeAll: onSeeAll),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final brand = brands[index];
              return SizedBox(
                width: 90,
                child: Material(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.08),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(
                          title: brand.title,
                          brandId: brand.id,
                        ),
                      ),
                    ),
                    // Только логотип, без названия (как на сайте).
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Semantics(
                        label: brand.title,
                        child: AppNetworkImage(
                          url: brand.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.headingText,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton.icon(
              onPressed: onSeeAll,
              label: Text(context.read<LocaleProvider>().t('see_all')),
              iconAlignment: IconAlignment.end,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedChevronRight,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({
    required this.future,
    required this.title,
    required this.onSeeAll,
  });

  final Future<List<ItemSummary>> future;
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ItemSummary>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ProductSectionSkeleton();
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        final preview = items.take(4).toList();
        return Column(
          children: [
            _SectionHeader(title: title, onSeeAll: onSeeAll),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Сетка по высоте обрезает всё, что вылезает за её край, — без
              // отступа сверху/снизу тень карточек срезалась, и низ выглядел
              // плоским. Отступ оставляет место и для тени.
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 22),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              itemCount: preview.length,
              itemBuilder: (context, index) => ProductCard(item: preview[index]),
            ),
          ],
        );
      },
    );
  }
}
