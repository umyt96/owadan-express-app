import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../utils/image_preload.dart';
import '../widgets/appear_in_turn.dart';
import '../models/item.dart';
import '../providers/locale_provider.dart';
import '../services/catalog_service.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/product_card.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/illustrated_empty_state.dart';

class ProductListScreen extends StatefulWidget {
  final String title;
  final String? categorySlug;
  final String? parentCategorySlug;
  final int? brandId;
  final String? search;
  final String? ordering;
  final bool onlyDiscounted;
  /// Страница «В наличии» — только товары с галочкой «Есть в наличии».
  final bool onlyInStock;

  const ProductListScreen({
    super.key,
    required this.title,
    this.categorySlug,
    this.parentCategorySlug,
    this.brandId,
    this.search,
    this.ordering,
    this.onlyDiscounted = false,
    this.onlyInStock = false,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _catalogService = CatalogService();
  final List<ItemSummary> _items = [];

  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int? _totalCount;
  ProductFilters _filters = const ProductFilters();

  @override
  void initState() {
    super.initState();
    _loadPage(reset: true);
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _items.clear();
        _totalCount = null;
      }
    });
    try {
      // Все фильтры (цена, скидки, наличие) теперь делает сервер — одна
      // страница за раз, без лишних запросов и ошибки «Неправильная страница».
      final result = await _catalogService.getItems(
        categorySlug: widget.categorySlug,
        parentCategorySlug: widget.parentCategorySlug,
        brandId: widget.brandId,
        colorId: _filters.colorId,
        sizeId: _filters.sizeId,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        search: widget.search,
        ordering: widget.ordering,
        inStockOnly: _inStockOnly,
        discountedOnly: widget.onlyDiscounted,
        page: _page,
      );
      if (!mounted) return;
      await precacheItemImages(context, result.results);
      if (!mounted) return;
      setState(() {
        _totalCount = result.count;
        _items.addAll(result.results);
        _hasMore = result.next != null;
        _page++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openFilters() async {
    // На странице «В наличии» галочка «Только в наличии» не нужна.
    final result = await showFiltersSheet(context, current: _filters, showInStock: !widget.onlyInStock);
    if (result != null) {
      setState(() => _filters = result);
      _loadPage(reset: true);
    }
  }

  bool get _inStockOnly => widget.onlyInStock || _filters.inStockOnly;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, overflow: TextOverflow.ellipsis),
            if (_totalCount != null)
              Text(
                '${locale.t('found_count')}: $_totalCount',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: !_filters.isEmpty,
              label: const Text(''),
              smallSize: 8,
              child: const HugeIcon(icon: HugeIcons.strokeRoundedFilterHorizontal),
            ),
            tooltip: locale.t('filters'),
            onPressed: _openFilters,
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(reset: true),
        child: _buildBody(locale),
      ),
    );
  }

  Widget _buildBody(LocaleProvider locale) {
    if (_items.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return Center(child: Text('${locale.t('error')}: $_error'));
    }
    if (_items.isEmpty && !_hasMore) {
      return IllustratedEmptyState(
        image: EmptyIllustrations.catalog,
        title: locale.t('nothing_found'),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.62,
      ),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          // подгрузка следующей страницы при достижении конца списка
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage());
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ));
        }
        return AppearInTurn(
          id: _items[index].id,
          index: index,
          child: ProductCard(item: _items[index]),
        );
      },
    );
  }
}
