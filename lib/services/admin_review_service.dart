import 'package:dio/dio.dart';

import '../models/admin_review.dart';
import 'api_client.dart';

/// Раздел "Отзывы" — только для суперпользователя.
class AdminReviewService {
  final Dio _dio = ApiClient.instance.dio;

  Future<({List<AdminReview> items, bool hasMore})> getReviews({
    int page = 1,
    int? rating,
    bool hiddenOnly = false,
    String? search,
  }) async {
    try {
      final response = await _dio.get('/admin-reviews/', queryParameters: {
        'page': page,
        if (rating != null) 'rating': rating,
        if (hiddenOnly) 'hidden': 1,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final data = response.data;
      final list = data is Map && data['results'] != null ? data['results'] as List : data as List;
      return (
        items: list.map((e) => AdminReview.fromJson(e)).toList(),
        hasMore: data is Map && data['next'] != null,
      );
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> setVisible(int id, bool visible) async {
    try {
      await _dio.patch('/admin-reviews/$id/', data: {'status': visible});
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/admin-reviews/$id/');
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<ReviewStats?> getStats() async {
    try {
      final response = await _dio.get('/admin-reviews/stats/');
      return ReviewStats.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }
}
