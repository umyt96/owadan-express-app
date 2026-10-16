import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../models/order_stats.dart';
import '../models/refund_request.dart';
import 'api_client.dart';
import 'catalog_service.dart' show PaginatedResult;

/// Увеличивается каждый раз, когда где-либо в приложении заказ был изменён,
/// удалён или оформлен — экраны, показывающие количество/список заказов
/// (например, счётчик в профиле), слушают это значение, чтобы обновиться
/// даже если сами не пересоздавались (например, при возврате со страницы
/// "Все заказы" через кнопку "назад", а не переключением вкладки).
final ValueNotifier<int> ordersChangedTick = ValueNotifier(0);

class CheckoutService {
  final Dio _dio = ApiClient.instance.dio;

  /// Оформляет текущую корзину в заказ.
  /// Укажите либо [addressId] (сохранённый адрес), либо поля нового адреса
  /// ([streetAddress], [country], [phone] — обязательны вместе).
  /// Если ничего не передать — используется адрес по умолчанию пользователя.
  Future<AppOrder> checkout({
    int? addressId,
    String? streetAddress,
    String? apartmentAddress,
    String? country,
    String? phone,
    bool setDefault = false,
    String? couponCode,
    List<int>? itemIds,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.post('/checkout/', data: {
        if (itemIds != null && itemIds.isNotEmpty) 'item_ids': itemIds,
        if (addressId != null) 'address_id': addressId,
        if (streetAddress != null) 'street_address': streetAddress,
        if (apartmentAddress != null) 'apartment_address': apartmentAddress,
        if (country != null) 'country': country,
        if (phone != null) 'phone': phone,
        'set_default': setDefault,
        if (couponCode != null) 'coupon_code': couponCode,
        // Местоположение по GPS — необязательно.
        if (latitude != null && longitude != null) ...{'latitude': latitude, 'longitude': longitude},
      });
      return AppOrder.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<PaginatedResult<AppOrder>> getOrderHistory({int page = 1}) async {
    try {
      final response = await _dio.get('/orders/', queryParameters: {'page': page});
      return PaginatedResult.fromJson(response.data, (json) => AppOrder.fromJson(json));
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> requestRefund({required String refCode, required String message}) async {
    try {
      await _dio.post('/orders/request-refund/', data: {
        'ref_code': refCode,
        'message': message,
      });
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  // --- Ниже — только для суперпользователя (раздел "Заказы" в профиле) ---
  //
  // ВАЖНО: /orders/all/ — предполагаемый путь по аналогии с /orders/ для
  // истории покупок текущего пользователя. Такого эндпоинта в REST API могло
  // не быть, если раньше администрирование заказов делалось только через
  // Django-админку/отдельную orders-панель на сайте (как в присланном
  // orders.zip). Если бэкенд ответит 404 — экран покажет понятную ошибку,
  // и нужно будет либо добавить такой эндпоинт на сервере, либо сообщить
  // мне правильный путь, чтобы я его подставил.

  Future<PaginatedResult<AppOrder>> getAllOrders({int page = 1, int? userId}) async {
    try {
      final response = await _dio.get('/orders/all/', queryParameters: {
        'page': page,
        if (userId != null) 'user_id': userId,
      });
      return PaginatedResult.fromJson(response.data, (json) => AppOrder.fromJson(json));
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Клиенты, у которых есть хотя бы один оформленный заказ — для фильтра
  /// "Все заказы" по клиенту.
  Future<List<OrderCustomer>> getOrderCustomers({String search = ''}) async {
    try {
      final response = await _dio.get('/orders/customers/', queryParameters: {
        if (search.isNotEmpty) 'search': search,
      });
      return (response.data as List).map((e) => OrderCustomer.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<OrderStats> getOrderStats() async {
    try {
      final response = await _dio.get('/orders/stats/');
      return OrderStats.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Обновляет статус заказа (галочки как на сайте) и/или аванс/стоимость
  /// доставки одним запросом — соответствует форме "Изменить статус заказа"
  /// на сайте.
  Future<void> updateOrder({
    required int orderId,
    bool? pending,
    bool? beingDelivered,
    bool? received,
    bool? refundGranted,
    bool? cancel,
    num? avans,
    num? costOfDelivery,
  }) async {
    try {
      await _dio.patch('/orders/all/$orderId/', data: {
        if (pending != null) 'pending': pending,
        if (beingDelivered != null) 'being_delivered': beingDelivered,
        if (received != null) 'received': received,
        if (refundGranted != null) 'refund_granted': refundGranted,
        if (cancel != null) 'cancel': cancel,
        if (avans != null) 'avans': avans,
        if (costOfDelivery != null) 'cost_of_delivery': costOfDelivery,
      });
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> deleteOrderAsAdmin(int orderId) async {
    try {
      await _dio.delete('/orders/all/$orderId/');
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<PaginatedResult<RefundRequest>> getAllRefunds({int page = 1}) async {
    try {
      final response = await _dio.get('/refunds/all/', queryParameters: {'page': page});
      return PaginatedResult.fromJson(response.data, (json) => RefundRequest.fromJson(json));
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> setRefundAccepted({required int refundId, required bool accepted}) async {
    try {
      await _dio.patch('/refunds/all/$refundId/', data: {'accepted': accepted});
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}
