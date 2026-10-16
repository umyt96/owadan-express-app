class BannerItem {
  final int id;
  final String? image;
  final String? description;

  BannerItem({required this.id, this.image, this.description});

  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(
        id: json['id'],
        image: json['image'],
        description: json['description'],
      );
}
