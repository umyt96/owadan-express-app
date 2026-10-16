class Brand {
  final int id;
  final String title;
  final String? image;

  Brand({required this.id, required this.title, this.image});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'],
        title: json['title'] ?? '',
        image: json['image'],
      );
}
