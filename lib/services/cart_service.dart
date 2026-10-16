import 'package:dio/dio.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import 'api_client.dart';

class CartService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<CartItem>> getCart() async {
    try {
      final response = await _dio.get('/cart/');
      return (response.data as List).map((e) => CartItem.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<CartItem> addToCart({
    required String slug,
    int quantity = 1,
    String? size,
    String? color,
  }) async {
    try {
      final response = await _dio.post('/cart/add/', data: {
        'slug': slug,
        'quantity': quantity,
        if (size != null) 'size': size,
        if (color != null) 'color': color,
      });
      return CartItem.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<CartItem> updateQuantity(int cartItemId, int quantity) async {
    try {
      final response =
          await _dio.patch('/cart/$cartItemId/update_quantity/', data: {
        'quantity': quantity,
      });
      return CartItem.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    try {
      await _dio.delete('/cart/$cartItemId/');
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Возвращает заказ с пересчитанной суммой (total уже учитывает скидку купона).
  Future<AppOrder> applyCoupon(String code) async {
    try {
      final response = await _dio.post('/cart/apply-coupon/', data: {'code': code});
      return AppOrder.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}
