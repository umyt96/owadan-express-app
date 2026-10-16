import 'cart_item.dart';

class RefundRequest {
  final int id;
  final String orderRefCode;
  final String? username;
  final String reason;
  final bool accepted;
  final DateTime? createdDate;
  final List<CartItem> orderItems;

  RefundRequest({
    required this.id,
    required this.orderRefCode,
    this.username,
    required this.reason,
    required this.accepted,
    this.createdDate,
    required this.orderItems,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) => RefundRequest(
        id: json['id'],
        orderRefCode: json['order_ref_code'] ?? '',
        username: json['username'],
        reason: json['reason'] ?? '',
        accepted: json['accepted'] ?? false,
        createdDate: json['created_date'] != null ? DateTime.tryParse(json['created_date']) : null,
        orderItems: (json['order_items'] as List? ?? []).map((e) => CartItem.fromJson(e)).toList(),
      );
}
