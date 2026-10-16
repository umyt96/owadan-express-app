class OrderStats {
  final int today;
  final int lastWeek;
  final int thisMonth;
  final int thisYear;
  final int total;

  OrderStats({
    required this.today,
    required this.lastWeek,
    required this.thisMonth,
    required this.thisYear,
    required this.total,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) => OrderStats(
        today: json['today'] ?? 0,
        lastWeek: json['last_week'] ?? 0,
        thisMonth: json['this_month'] ?? 0,
        thisYear: json['this_year'] ?? 0,
        total: json['total'] ?? 0,
      );
}


/// Клиент с оформленными заказами (фильтр в "Все заказы").
class OrderCustomer {
  final int id;
  final String username;
  final String email;
  final String name;
  final int ordersCount;
  final DateTime? lastOrder;

  OrderCustomer({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.ordersCount,
    this.lastOrder,
  });

  /// Имя для показа: "Имя Фамилия (логин)" или просто логин.
  String get label => name.isNotEmpty ? '$name ($username)' : username;

  factory OrderCustomer.fromJson(Map<String, dynamic> json) => OrderCustomer(
        id: json['id'],
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? '',
        ordersCount: json['orders_count'] ?? 0,
        lastOrder: json['last_order'] != null ? DateTime.tryParse(json['last_order']) : null,
      );
}
