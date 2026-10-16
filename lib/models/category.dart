class AllCategory {
  final int id;
  final String titleRu;
  final String titleTk;
  // Английское название; пусто — показываем русское.
  final String titleEn;
  final String slug;
  final String? image;

  AllCategory({
    required this.id,
    required this.titleRu,
    required this.titleTk,
    this.titleEn = '',
    required this.slug,
    this.image,
  });

  String titleFor(String lang) => lang == 'tk' && titleTk.isNotEmpty
      ? titleTk
      : lang == 'en' && titleEn.isNotEmpty
          ? titleEn
          : titleRu;

  factory AllCategory.fromJson(Map<String, dynamic> json) => AllCategory(
        id: json['id'],
        titleRu: json['title_ru'] ?? '',
        titleTk: json['title_tk'] ?? '',
        titleEn: json['title_en'] ?? '',
        slug: json['slug'] ?? '',
        image: json['image'],
      );
}

/// Подкатегория (core.models.Category)
class ProductCategory {
  final int id;
  final int? type;
  final String titleRu;
  final String titleTk;
  // Английское название; пусто — показываем русское.
  final String titleEn;
  final String slug;
  final String? image;

  ProductCategory({
    required this.id,
    this.type,
    required this.titleRu,
    required this.titleTk,
    this.titleEn = '',
    required this.slug,
    this.image,
  });

  String titleFor(String lang) => lang == 'tk' && titleTk.isNotEmpty
      ? titleTk
      : lang == 'en' && titleEn.isNotEmpty
          ? titleEn
          : titleRu;

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: json['id'],
        type: json['type'],
        titleRu: json['title_ru'] ?? '',
        titleTk: json['title_tk'] ?? '',
        titleEn: json['title_en'] ?? '',
        slug: json['slug'] ?? '',
        image: json['image'],
      );
}
