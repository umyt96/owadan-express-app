import 'address.dart';
import 'cart_item.dart';

class AppOrder {
  final int id;
  final String refCode;
  final List<CartItem> items;
  final DateTime? orderedDate;
  final bool ordered;
  final num? total;
  final String status;
  final Address? shippingAddress;
  final num? costOfDelivery;
  final num? avans;
  final String? username;
  final bool? pending;
  final bool? beingDelivered;
  final bool? received;
  final bool? refundGranted;
  final bool? cancel;

  AppOrder({
    required this.id,
    required this.refCode,
    required this.items,
    this.orderedDate,
    required this.ordered,
    this.total,
    required this.status,
    this.shippingAddress,
    this.costOfDelivery,
    this.avans,
    this.username,
    this.pending,
    this.beingDelivered,
    this.received,
    this.refundGranted,
    this.cancel,
  });

  factory AppOrder.fromJson(Map<String, dynamic> json) => AppOrder(
        id: json['id'],
        refCode: json['ref_code'] ?? '',
        items: (json['items'] as List? ?? [])
            .map((e) => CartItem.fromJson(e))
            .toList(),
        orderedDate: json['ordered_date'] != null
            ? DateTime.tryParse(json['ordered_date'])
            : null,
        ordered: json['ordered'] ?? false,
        total: json['total'],
        status: json['status'] ?? 'unknown',
        shippingAddress: json['shipping_address'] != null
            ? Address.fromJson(json['shipping_address'])
            : null,
        costOfDelivery: json['cost_of_delivery'],
        avans: json['avans'],
        username: json['username'] ?? json['user']?['username'],
        pending: json['pending'],
        beingDelivered: json['being_delivered'],
        received: json['received'],
        refundGranted: json['refund_granted'],
        cancel: json['cancel'],
      );
}
