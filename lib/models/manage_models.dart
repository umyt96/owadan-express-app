/// Модели раздела "Товары" (добавление/изменение товаров персоналом).
/// Цены здесь — в юанях (CNY), как в админке сайта.
library;

/// Число из JSON: сервер мог вернуть id строкой ("5") — принимаем и так.
int? _toInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));

class ManageItem {
  final int id;
  final String slug;
  final String titleRu;
  final String titleTk;
  final String? image;
  final double price;
  final double? discountPrice;
  final int? priceTmt;
  final int quantity;
  final bool isPublished;
  final bool inStock; // "Есть в наличии" (Nagt bar)
  final String categoryTitle;

  ManageItem({
    required this.id,
    required this.slug,
    required this.titleRu,
    required this.titleTk,
    this.image,
    required this.price,
    this.discountPrice,
    this.priceTmt,
    required this.quantity,
    required this.isPublished,
    this.inStock = true,
    required this.categoryTitle,
  });

  String titleFor(String lang) => lang == 'tk' && titleTk.isNotEmpty ? titleTk : titleRu;

  factory ManageItem.fromJson(Map<String, dynamic> j) => ManageItem(
        id: j['id'],
        slug: j['slug'] ?? '',
        titleRu: j['title_ru'] ?? '',
        titleTk: j['title_tk'] ?? '',
        image: j['image'],
        price: (j['price'] as num?)?.toDouble() ?? 0,
        discountPrice: (j['discount_price'] as num?)?.toDouble(),
        priceTmt: (j['price_tmt'] as num?)?.toInt(),
        quantity: j['quantity'] ?? 0,
        isPublished: j['is_published'] ?? true,
        inStock: j['in_stock'] ?? true,
        categoryTitle: j['category_title'] ?? '',
      );
}

class ManageImage {
  final int id;
  final String image;
  ManageImage({required this.id, required this.image});
  factory ManageImage.fromJson(Map<String, dynamic> j) => ManageImage(id: j['id'], image: j['image'] ?? '');
}

class ManageItemDetail extends ManageItem {
  final String descriptionRu; // HTML как на сайте
  final String descriptionTk;
  final int? categoryId;
  final int? allCategoryId;
  final int? brandId;
  final int? delivery;
  final List<int> sizeIds;
  final List<int> colorIds;
  final List<RefOption> sizes;
  final List<RefOption> colors;
  final List<ManageImage> images;
  final List<SizePrice> sizePrices;

  ManageItemDetail.fromJson(Map<String, dynamic> j)
      : descriptionRu = j['description_ru'] ?? '',
        descriptionTk = j['description_tk'] ?? '',
        categoryId = _toInt(j['category_id']),
        allCategoryId = _toInt(j['all_category_id']),
        brandId = _toInt(j['brand_id']),
        delivery = _toInt(j['delivery']),
        sizeIds = (j['size_ids'] as List? ?? const []).map(_toInt).whereType<int>().toList(),
        colorIds = (j['color_ids'] as List? ?? const []).map(_toInt).whereType<int>().toList(),
        sizes = (j['sizes'] as List? ?? []).map((e) => RefOption.size(e)).toList(),
        colors = (j['colors'] as List? ?? []).map((e) => RefOption.color(e)).toList(),
        images = (j['images'] as List? ?? []).map((e) => ManageImage.fromJson(e)).toList(),
        sizePrices = (j['size_prices'] as List? ?? []).map((e) => SizePrice.fromJson(e)).toList(),
        super(
          id: j['id'],
          slug: j['slug'] ?? '',
          titleRu: j['title_ru'] ?? '',
          titleTk: j['title_tk'] ?? '',
          image: j['image'],
          price: (j['price'] as num?)?.toDouble() ?? 0,
          discountPrice: (j['discount_price'] as num?)?.toDouble(),
          priceTmt: (j['price_tmt'] as num?)?.toInt(),
          quantity: j['quantity'] ?? 0,
          isPublished: j['is_published'] ?? true,
          inStock: j['in_stock'] ?? true,
          categoryTitle: j['category_title'] ?? '',
        );
}

/// Своя цена товара для размера (CNY). Нет записи — действует цена товара.
class SizePrice {
  final int sizeId;
  final double price;
  final double? discountPrice;
  SizePrice({required this.sizeId, required this.price, this.discountPrice});

  factory SizePrice.fromJson(Map<String, dynamic> j) => SizePrice(
        sizeId: _toInt(j['size_id']) ?? 0,
        price: double.tryParse('${j['price']}') ?? 0,
        discountPrice: j['discount_price'] == null ? null : double.tryParse('${j['discount_price']}'),
      );

  Map<String, dynamic> toJson() => {'size_id': sizeId, 'price': price, 'discount_price': discountPrice};
}

/// Размер или цвет (справочник).
class RefOption {
  final int id;
  final String titleRu;
  final String titleTk;
  RefOption({required this.id, required this.titleRu, this.titleTk = ''});
  String titleFor(String lang) => lang == 'tk' && titleTk.isNotEmpty ? titleTk : titleRu;

  factory RefOption.size(Map<String, dynamic> j) => RefOption(id: j['id'], titleRu: j['title'] ?? '');
  factory RefOption.color(Map<String, dynamic> j) => RefOption(id: j['id'], titleRu: j['title_ru'] ?? '', titleTk: j['title_tk'] ?? '');
}

class CategoryNode {
  final int id;
  final String titleRu;
  final String titleTk;
  final List<CategoryNode> children;
  CategoryNode({required this.id, required this.titleRu, required this.titleTk, this.children = const []});
  String titleFor(String lang) => lang == 'tk' && titleTk.isNotEmpty ? titleTk : titleRu;

  factory CategoryNode.fromJson(Map<String, dynamic> j) => CategoryNode(
        id: j['id'],
        titleRu: j['title_ru'] ?? '',
        titleTk: j['title_tk'] ?? '',
        children: (j['children'] as List? ?? []).map((e) => CategoryNode.fromJson(e)).toList(),
      );
}

class ManageMeta {
  final double? yuan;
  final double? dollar;
  final List<CategoryNode> categories;
  final List<RefOption> brands;
  final bool canDelete;

  ManageMeta({this.yuan, this.dollar, required this.categories, required this.brands, required this.canDelete});

  /// Цена в TMT — ровно как на сайте: ceil(price / yuan * dollar).
  int? toTmt(double? cny) {
    if (cny == null || yuan == null || dollar == null || yuan == 0) return null;
    return (cny / yuan! * dollar!).ceil();
  }

  factory ManageMeta.fromJson(Map<String, dynamic> j) => ManageMeta(
        yuan: (j['currency']?['yuan'] as num?)?.toDouble(),
        dollar: (j['currency']?['dollar'] as num?)?.toDouble(),
        categories: (j['categories'] as List? ?? []).map((e) => CategoryNode.fromJson(e)).toList(),
        brands: (j['brands'] as List? ?? []).map((e) => RefOption(id: e['id'], titleRu: e['title'] ?? '')).toList(),
        canDelete: j['can_delete'] ?? false,
      );
}
