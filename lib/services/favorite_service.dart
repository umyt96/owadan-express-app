import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/item.dart';
import 'api_client.dart';

/// Увеличивается при каждом изменении избранного с карточки или страницы
/// товара — экран «Избранное» живёт в IndexedStack и по нему перезагружается.
final ValueNotifier<int> favoritesVersion = ValueNotifier(0);

class FavoriteService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ItemSummary>> getFavorites() async {
    try {
      final response = await _dio.get('/favorites/');
      final list = response.data as List;
      return list.map((e) => ItemSummary.fromJson(e['item'])).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Возвращает true, если товар теперь в избранном, false — если убран.
  Future<bool> toggleFavorite(String slug) async {
    final liked = await _toggle(slug);
    favoritesVersion.value++;
    return liked;
  }

  Future<bool> _toggle(String slug) async {
    try {
      if (kDebugMode) {
        debugPrint('\x1B[36m[FavoriteAPI][request] POST /favorites/ '
            '{slug: $slug}\x1B[0m');
      }
      final response = await _dio.post('/favorites/', data: {'slug': slug});
      if (kDebugMode) {
        debugPrint('\x1B[32m[FavoriteAPI][response] '
            'status: ${response.statusCode}, data: ${response.data}\x1B[0m');
      }
      final data = response.data;
      if (data is! Map || data['liked'] is! bool) {
        throw FormatException('Unexpected favorite response: $data');
      }
      return data['liked'] as bool;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('\x1B[31m[FavoriteAPI][error] '
            'status: ${e.response?.statusCode}, data: ${e.response?.data}, '
            'message: ${e.message}\x1B[0m');
      }
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Удаляет один товар из избранного (toggle на сервере, но здесь мы точно
  /// знаем, что товар сейчас в избранном — значит, он будет убран).
  Future<void> removeFavorite(String slug) async {
    final liked = await _toggle(slug);
    if (liked) {
      // На случай рассинхрона — если сервер вдруг добавил, снова убираем.
      await _toggle(slug);
    }
  }

  Future<void> clearFavorites() async {
    try {
      await _dio.post('/favorites/clear/');
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}
