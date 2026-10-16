import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../services/analytics_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();

  List<CartItem> items = [];
  bool isLoading = false;
  String? errorMessage;

  String? appliedCouponCode;
  num? couponTotal; // итог, посчитанный сервером после применения купона

  /// id позиций корзины, отмеченных галочкой для оформления. Новые позиции
  /// отмечены по умолчанию; невыбранные останутся в корзине после заказа.
  final Set<int> selectedIds = {};

  /// Лежит ли товар (с любым размером/цветом) в корзине сейчас.
  bool containsSlug(String slug) => items.any((i) => i.item.slug == slug);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  List<CartItem> get selectedItems => items.where((i) => selectedIds.contains(i.id)).toList();

  bool get allSelected => items.isNotEmpty && selectedIds.length == items.length;

  num get subtotal => selectedItems.fold(0, (sum, item) => sum + (item.totalPrice ?? 0));

  /// Итог к оплате — купон сервер считает по всей корзине, поэтому
  /// используем его итог, только если выбраны все позиции.
  num get total => (allSelected && couponTotal != null) ? couponTotal! : subtotal;

  void toggleSelected(int id) {
    if (!selectedIds.remove(id)) selectedIds.add(id);
    notifyListeners();
  }

  void setAllSelected(bool value) {
    selectedIds
      ..clear()
      ..addAll(value ? items.map((i) => i.id) : const <int>[]);
    notifyListeners();
  }

  /// После выхода из аккаунта: корзина принадлежит аккаунту, поэтому
  /// очищаем её локально (на сервере она остаётся) — иначе на значке
  /// корзины висело бы число товаров прежнего пользователя.
  void clearLocal() {
    items = [];
    selectedIds.clear();
    appliedCouponCode = null;
    couponTotal = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> loadCart() async {
    isLoading = true;
    notifyListeners();
    try {
      final previousIds = items.map((i) => i.id).toSet();
      items = await _cartService.getCart();
      final currentIds = items.map((i) => i.id).toSet();
      selectedIds.removeWhere((id) => !currentIds.contains(id));
      // новые позиции (только что добавленные) — сразу отмечены
      selectedIds.addAll(currentIds.difference(previousIds));
      errorMessage = null;
      // состав корзины изменился — старый пересчитанный купоном итог больше не актуален
      appliedCouponCode = null;
      couponTotal = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(String slug, {int quantity = 1, String? size, String? color}) async {
    try {
      await _cartService.addToCart(slug: slug, quantity: quantity, size: size, color: color);
      AnalyticsService.instance.event('add_to_cart', data: {'product': slug, 'quantity': quantity});
      await loadCart();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    await _cartService.updateQuantity(cartItemId, quantity);
    await loadCart();
  }

  Future<void> removeItem(int cartItemId) async {
    await _cartService.removeFromCart(cartItemId);
    await loadCart();
  }

  /// Удаляет из корзины все отмеченные галочкой позиции.
  Future<void> removeSelected() async {
    final ids = selectedIds.toList();
    if (ids.isEmpty) return;
    try {
      await Future.wait(ids.map(_cartService.removeFromCart));
    } finally {
      await loadCart();
    }
  }

  Future<bool> applyCoupon(String code) async {
    try {
      final order = await _cartService.applyCoupon(code);
      appliedCouponCode = code;
      couponTotal = order.total;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Очищает локальное состояние (например, при выходе из аккаунта или после оформления заказа).
  void reset() {
    items = [];
    selectedIds.clear();
    appliedCouponCode = null;
    couponTotal = null;
    notifyListeners();
  }
}
