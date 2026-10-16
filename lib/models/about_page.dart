class AboutPage {
  final int id;
  final String titleRu;
  final String textRu;
  final String titleTk;
  final String textTk;
  final String titleEn;
  final String textEn;

  AboutPage({
    required this.id,
    required this.titleRu,
    required this.textRu,
    required this.titleTk,
    required this.textTk,
    this.titleEn = '',
    this.textEn = '',
  });

  String titleFor(String lang) => lang == 'tk' && titleTk.isNotEmpty
      ? titleTk
      : lang == 'en' && titleEn.isNotEmpty
          ? titleEn
          : titleRu;
  String textFor(String lang) => lang == 'tk' && textTk.isNotEmpty
      ? textTk
      : lang == 'en' && textEn.isNotEmpty
          ? textEn
          : textRu;

  factory AboutPage.fromJson(Map<String, dynamic> json) => AboutPage(
        id: json['id'],
        titleRu: json['title_ru'] ?? '',
        textRu: json['text_ru'] ?? '',
        titleTk: json['title_tk'] ?? '',
        textTk: json['text_tk'] ?? '',
        titleEn: json['title_en'] ?? '',
        textEn: json['text_en'] ?? '',
      );
}
