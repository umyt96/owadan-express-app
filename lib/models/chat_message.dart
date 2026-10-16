class ChatMessage {
  final int id;
  final String message;
  final String? answer;
  final DateTime? createdDate;
  final MessageProduct? product;
  // Заполняются только в админском разделе (кто написал, прочитано ли).
  final String? username;
  final int? userId;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.message,
    this.answer,
    this.createdDate,
    this.product,
    this.username,
    this.userId,
    this.isRead = true,
  });

  /// Сообщение, начатое администратором (без вопроса клиента).
  bool get isFromAdmin => message.trim().isEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        message: json['message'] ?? '',
        answer: (json['answer'] as String?)?.isNotEmpty == true ? json['answer'] : null,
        createdDate: json['created_date'] != null
            ? DateTime.tryParse(json['created_date'])
            : null,
        product: json['product_detail'] != null ? MessageProduct.fromJson(json['product_detail']) : null,
        username: json['username'],
        userId: json['user_id'],
        isRead: json['is_read'] ?? true,
      );
}

/// Краткая информация о товаре, к которому относится сообщение
/// "Обратиться к администратору" — фото и название, чтобы показать рядом
/// с сообщением в чате (как на сайте) и дать перейти на страницу товара.
class MessageProduct {
  final int id;
  final String slug;
  final String titleRu;
  final String titleTk;
  final String titleEn;
  final String? image;

  MessageProduct({
    required this.id,
    required this.slug,
    required this.titleRu,
    required this.titleTk,
    this.titleEn = '',
    this.image,
  });

  String titleFor(String lang) => lang == 'tk' && titleTk.isNotEmpty
      ? titleTk
      : lang == 'en' && titleEn.isNotEmpty
          ? titleEn
          : titleRu;

  factory MessageProduct.fromJson(Map<String, dynamic> json) => MessageProduct(
        id: json['id'],
        slug: json['slug'] ?? '',
        titleRu: json['title_ru'] ?? '',
        titleTk: json['title_tk'] ?? '',
        titleEn: json['title_en'] ?? '',
        image: json['image'],
      );
}
