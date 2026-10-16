import 'brand.dart';
import 'category.dart';

class ItemSize {
  final int id;
  final String title;
  // Своя цена товара для этого размера (TMT); null — действует цена товара.
  final double? price;
  final double? discountPrice;

  ItemSize({required this.id, required this.title, this.price, this.discountPrice});

  // Подпись для выбора размера: "XL · 520 ТМТ", если у размера своя цена.
  String get label {
    final p = discountPrice ?? price;
    return p == null ? title : '$title · ${p.round()} ТМТ';
  }

  factory ItemSize.fromJson(Map<String, dynamic> json) => ItemSize(
        id: json['id'],
        title: json['title'] ?? '',
        price: (json['price'] as num?)?.toDouble(),
        discountPrice: (json['discount_price'] as num?)?.toDouble(),
      );
}

class ItemImage {
  final int id;
  final String title;
  final String? image;

  ItemImage({required this.id, required this.title, this.image});

  factory ItemImage.fromJson(Map<String, dynamic> json) => ItemImage(
        id: json['id'],
        title: json['title'] ?? '',
        image: json['image'],
      );
}

class ItemColor {
  final int id;
  final String title;
  final ItemImage? image;
  final ItemSize? size;

  ItemColor({required this.id, required this.title, this.image, this.size});

  factory ItemColor.fromJson(Map<String, dynamic> json) => ItemColor(
        id: json['id'],
        title: json['title'] ?? '',
        image: json['image'] != null ? ItemImage.fromJson(json['image']) : null,
        size: json['size'] != null ? ItemSize.fromJson(json['size']) : null,
      );
}

/// Лёгкая модель товара — для списков: каталог, поиск, корзина, избранное.
/// Цены — в манатах (ТМТ), как на сайте (не доллары, несмотря на то что
/// внутри Django-модели метод называется conversion_price()).
class ItemSummary {
  final int id;
  final String titleRu;
  final String titleTk;
  // Английское название; пусто — показываем русское.
  final String titleEn;
  final String slug;
  final String? image;
  final int? price;
  final int? discountPrice;
  final int? sale;
  final String? category; // slug подкатегории
  final String? categoryTitleRu;
  final String? categoryTitleTk;
  final String? categoryTitleEn;
  final String? brand; // title бренда
  final int quantity;
  final int views;
  final bool isFavorite;

  ItemSummary({
    required this.id,
    required this.titleRu,
    required this.titleTk,
    this.titleEn = '',
    required this.slug,
    this.image,
    this.price,
    this.discountPrice,
    this.sale,
    this.category,
    this.categoryTitleRu,
    this.categoryTitleTk,
    this.categoryTitleEn,
    this.brand,
    required this.quantity,
    required this.views,
    this.isFavorite = false,
  });

  /// Название на нужном языке ('ru', 'tk' или 'en'), с запасным вариантом на
  /// русском, если перевод не заполнен.
  String titleFor(String lang) => lang == 'tk' && titleTk.isNotEmpty
      ? titleTk
      : lang == 'en' && titleEn.isNotEmpty
          ? titleEn
          : titleRu;

  /// Цена к показу (в манатах) — со скидкой, если она задана, иначе обычная.
  int? get displayPrice => discountPrice ?? price;

  ItemSummary copyWithFavorite(bool value) => ItemSummary(
        id: id,
        titleRu: titleRu,
        titleTk: titleTk,
        titleEn: titleEn,
        slug: slug,
        image: image,
        price: price,
        discountPrice: discountPrice,
        sale: sale,
        category: category,
        categoryTitleRu: categoryTitleRu,
        categoryTitleTk: categoryTitleTk,
        categoryTitleEn: categoryTitleEn,
        brand: brand,
        quantity: quantity,
        views: views,
        isFavorite: value,
      );

  /// Название подкатегории на нужном языке. Если сервер ещё не отдаёт
  /// названия (старая версия API) — slug, чуть приятнее глазу.
  String? categoryLabelFor(String lang) {
    final tk = categoryTitleTk ?? '';
    final ru = categoryTitleRu ?? '';
    final en = categoryTitleEn ?? '';
    if (lang == 'tk' && tk.isNotEmpty) return tk;
    if (lang == 'en' && en.isNotEmpty) return en;
    if (ru.isNotEmpty) return ru;
    if (category == null || category!.isEmpty) return null;
    final words = category!.replaceAll('-', ' ').replaceAll('_', ' ').split(' ');
    return words.map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  factory ItemSummary.fromJson(Map<String, dynamic> json) => ItemSummary(
        id: json['id'],
        titleRu: json['title_ru'] ?? '',
        titleTk: json['title_tk'] ?? '',
        titleEn: json['title_en'] ?? '',
        slug: json['slug'] ?? '',
        image: json['image'],
        price: json['price'],
        discountPrice: json['discount_price'],
        sale: json['sale'],
        category: json['category'],
        categoryTitleRu: json['category_title_ru'],
        categoryTitleTk: json['category_title_tk'],
        categoryTitleEn: json['category_title_en'],
        brand: json['brand'],
        quantity: json['quantity'] ?? 0,
        views: json['views'] ?? 0,
        isFavorite: json['is_favorite'] ?? false,
      );
}

class Review {
  final int id;
  final String user;
  final String review;
  final double rating;
  final DateTime? createdDate;
  final List<String> images;

  Review({
    required this.id,
    required this.user,
    required this.review,
    required this.rating,
    this.createdDate,
    this.images = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'],
        user: json['user'] ?? '',
        review: json['review'] ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        createdDate: json['created_date'] != null
            ? DateTime.tryParse(json['created_date'])
            : null,
        images: (json['images'] as List? ?? [])
            .map((e) => e['image'] as String?)
            .whereType<String>()
            .toList(),
      );
}

/// Полная модель товара — для страницы товара. Цены — в манатах (ТМТ).
class ItemDetail {
  final int id;
  final String titleRu;
  final String titleTk;
  final String titleEn;
  final String slug;
  final String? descriptionRu;
  final String? descriptionTk;
  final String? descriptionEn;
  final String? image;
  final List<ItemImage> images;
  final List<ItemSize> sizes;
  final List<ItemColor> colors;
  final int? delivery;
  final int? price;
  final int? discountPrice;
  final int? sale;
  final int quantity;
  // Галочка "Есть в наличии" (Nagt bar). Старый сервер её не отдаёт — true.
  final bool inStock;
  final int views;
  final ProductCategory? category;
  final Brand? brand;
  final List<Review> reviews;
  final double? averageRating;
  final int reviewsCount;

  ItemDetail({
    required this.id,
    required this.titleRu,
    required this.titleTk,
    this.titleEn = '',
    required this.slug,
    this.descriptionRu,
    this.descriptionTk,
    this.descriptionEn,
    this.image,
    required this.images,
    required this.sizes,
    required this.colors,
    this.delivery,
    this.price,
    this.discountPrice,
    this.sale,
    required this.quantity,
    this.inStock = true,
    required this.views,
    this.category,
    this.brand,
    required this.reviews,
    this.averageRating,
    required this.reviewsCount,
  });

  int? get displayPrice => discountPrice ?? price;

  // Цена с учётом выбранного размера: у размера своя цена — она, иначе цена товара.
  int? priceFor(ItemSize? size) => size?.price != null ? size!.price!.round() : price;
  int? discountPriceFor(ItemSize? size) => size?.price != null ? size!.discountPrice?.round() : discountPrice;
  int? displayPriceFor(ItemSize? size) => discountPriceFor(size) ?? priceFor(size);

  String titleFor(String lang) => lang == 'tk' && titleTk.isNotEmpty
      ? titleTk
      : lang == 'en' && titleEn.isNotEmpty
          ? titleEn
          : titleRu;

  String? descriptionFor(String lang) {
    if (lang == 'tk' && (descriptionTk?.isNotEmpty ?? false)) return descriptionTk;
    if (lang == 'en' && (descriptionEn?.isNotEmpty ?? false)) return descriptionEn;
    return descriptionRu;
  }

  factory ItemDetail.fromJson(Map<String, dynamic> json) => ItemDetail(
        id: json['id'],
        titleRu: json['title_ru'] ?? '',
        titleTk: json['title_tk'] ?? '',
        titleEn: json['title_en'] ?? '',
        slug: json['slug'] ?? '',
        descriptionRu: json['description_ru'],
        descriptionTk: json['description_tk'],
        descriptionEn: json['description_en'],
        image: json['image'],
        images: (json['images'] as List? ?? [])
            .map((e) => ItemImage.fromJson(e))
            .toList(),
        sizes: (json['size'] as List? ?? [])
            .map((e) => ItemSize.fromJson(e))
            .toList(),
        colors: (json['color'] as List? ?? [])
            .map((e) => ItemColor.fromJson(e))
            .toList(),
        delivery: json['delivery'],
        price: json['price'],
        discountPrice: json['discount_price'],
        sale: json['sale'],
        quantity: json['quantity'] ?? 0,
        inStock: json['in_stock'] ?? true,
        views: json['views'] ?? 0,
        category: json['category'] != null
            ? ProductCategory.fromJson(json['category'])
            : null,
        brand: json['brand'] != null ? Brand.fromJson(json['brand']) : null,
        reviews: (json['reviews'] as List? ?? [])
            .map((e) => Review.fromJson(e))
            .toList(),
        averageRating: (json['average_rating'] as num?)?.toDouble(),
        reviewsCount: json['reviews_count'] ?? 0,
      );
}
