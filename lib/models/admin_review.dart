import 'chat_message.dart' show MessageProduct;

/// Отзыв в админском разделе "Отзывы" — со всеми данными: товар, автор,
/// видимость (status), фото.
class AdminReview {
  final int id;
  final String username;
  final String review;
  final double rating;
  final bool visible;
  final DateTime? createdDate;
  final List<String> images;
  final MessageProduct? product;

  AdminReview({
    required this.id,
    required this.username,
    required this.review,
    required this.rating,
    required this.visible,
    this.createdDate,
    this.images = const [],
    this.product,
  });

  AdminReview copyWith({bool? visible}) => AdminReview(
        id: id,
        username: username,
        review: review,
        rating: rating,
        visible: visible ?? this.visible,
        createdDate: createdDate,
        images: images,
        product: product,
      );

  factory AdminReview.fromJson(Map<String, dynamic> json) => AdminReview(
        id: json['id'],
        username: json['username'] ?? json['user'] ?? '',
        review: json['review'] ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        visible: json['status'] ?? true,
        createdDate: json['created_date'] != null ? DateTime.tryParse(json['created_date']) : null,
        images: (json['images'] as List? ?? [])
            .map((e) => e['image'] as String?)
            .whereType<String>()
            .toList(),
        product: json['product_detail'] != null ? MessageProduct.fromJson(json['product_detail']) : null,
      );
}

class ReviewStats {
  final int total;
  final int hidden;
  final double? average;

  ReviewStats({required this.total, required this.hidden, this.average});

  factory ReviewStats.fromJson(Map<String, dynamic> json) => ReviewStats(
        total: json['total'] ?? 0,
        hidden: json['hidden'] ?? 0,
        average: (json['average'] as num?)?.toDouble(),
      );
}
