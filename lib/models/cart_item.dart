import 'item.dart';

class CartItem {
  final int id;
  final ItemSummary item;
  final int quantity;
  final String? selectSize;
  final String? selectColor;
  final num? totalPrice;

  CartItem({
    required this.id,
    required this.item,
    required this.quantity,
    this.selectSize,
    this.selectColor,
    this.totalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'],
        item: ItemSummary.fromJson(json['item']),
        quantity: json['quantity'] ?? 1,
        selectSize: json['selectSize'],
        selectColor: json['selectColor'],
        totalPrice: json['total_price'],
      );
}
