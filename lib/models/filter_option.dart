class FilterOption {
  final int id;
  final String title;

  FilterOption({required this.id, required this.title});

  factory FilterOption.fromJson(Map<String, dynamic> json) => FilterOption(
        id: json['id'],
        title: json['title'] ?? '',
      );
}
