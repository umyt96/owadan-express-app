import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/banner_item.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/filter_option.dart';
import '../models/item.dart';
import 'api_client.dart';

class PaginatedResult<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResult({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginatedResult(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List? ?? []).map((e) => fromJson(e)).toList(),
    );
  }
}

class CatalogService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<AllCategory>> getAllCategories() async {
    try {
      final response = await _dio.get('/all-categories/');
      return (response.data as List).map((e) => AllCategory.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<List<ProductCategory>> getSubCategories({String? parentSlug}) async {
    try {
      final response = await _dio.get('/categories/', queryParameters: {
        if (parentSlug != null) 'type__slug': parentSlug,
      });
      return (response.data as List)
          .map((e) => ProductCategory.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<List<Brand>> getBrands() async {
    try {
      final response = await _dio.get('/brands/');
      return (response.data as List).map((e) => Brand.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Баннеры для карусели на главной. Если на бэкенде такого эндпоинта нет
  /// (404) или он вернул ошибку — просто возвращаем пустой список, чтобы
  /// карусель не показывалась, а не ронять весь главный экран.
  Future<List<BannerItem>> getBanners() async {
    try {
      final response = await _dio.get('/banners/');
      final data = response.data is Map ? response.data['results'] : response.data;
      return (data as List).map((e) => BannerItem.fromJson(e)).toList();
    } on DioException catch (_) {
      return [];
    }
  }

  /// Список цветов для фильтра. Как и с баннерами — если такого эндпоинта
  /// нет на бэкенде, просто возвращаем пустой список, чтобы фильтр по цвету
  /// в интерфейсе не показывался, а не ронять экран.
  Future<List<FilterOption>> getColors() async {
    try {
      final response = await _dio.get('/colors/');
      final data = response.data is Map ? response.data['results'] : response.data;
      return (data as List).map((e) => FilterOption.fromJson(e)).toList();
    } on DioException catch (_) {
      return [];
    }
  }

  /// Список размеров для фильтра — та же логика, что и у getColors().
  Future<List<FilterOption>> getSizes() async {
    try {
      final response = await _dio.get('/sizes/');
      final data = response.data is Map ? response.data['results'] : response.data;
      return (data as List).map((e) => FilterOption.fromJson(e)).toList();
    } on DioException catch (_) {
      return [];
    }
  }

  Future<PaginatedResult<ItemSummary>> getItems({
    String? categorySlug,
    String? parentCategorySlug,
    int? brandId,
    int? colorId,
    int? sizeId,
    int? minPrice,
    int? maxPrice,
    String? search,
    String? ordering,
    bool inStockOnly = false,
    bool discountedOnly = false,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get('/items/', queryParameters: {
        if (categorySlug != null) 'category': categorySlug,
        if (parentCategorySlug != null) 'parent_category': parentCategorySlug,
        if (brandId != null) 'brand': brandId,
        if (colorId != null) 'color': colorId,
        if (sizeId != null) 'size': sizeId,
        // Цена в манатах (как видит покупатель) — фильтрует сервер.
        if (minPrice != null) 'price_min': minPrice,
        if (maxPrice != null) 'price_max': maxPrice,
        if (search != null) 'search': search,
        if (ordering != null) 'ordering': ordering,
        // Только товары с галочкой «Есть в наличии».
        if (inStockOnly) 'in_stock': 1,
        if (discountedOnly) 'discounted': 1,
        'page': page,
      });
      return PaginatedResult.fromJson(response.data, (json) => ItemSummary.fromJson(json));
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<ItemDetail> getItem(String slug) async {
    try {
      final response = await _dio.get('/items/$slug/');
      return ItemDetail.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// "Вам также может понравиться" — товары из той же подкатегории (как на сайте).
  Future<List<ItemSummary>> getSimilar(String slug) async {
    try {
      final response = await _dio.get('/items/$slug/similar/');
      return (response.data as List).map((e) => ItemSummary.fromJson(e)).toList();
    } catch (_) {
      return []; // блок необязательный — при ошибке просто не показываем
    }
  }

  Future<Review> submitReview(
    String slug, {
    required double rating,
    required String review,
    List<XFile> images = const [],
  }) async {
    try {
      final imageParts = await Future.wait(images.map((file) async {
        final bytes = await file.readAsBytes();
        return MultipartFile.fromBytes(bytes, filename: file.name);
      }));
      final formData = FormData.fromMap({
        'rating': rating,
        'review': review,
        'images': imageParts,
      });
      final response = await _dio.post('/items/$slug/reviews/', data: formData);
      return Review.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}
