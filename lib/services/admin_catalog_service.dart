import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';

/// Справочники сайта для суперпользователя: купоны, контакты, категории,
/// подкатегории, бренды, валюта. Один общий API на сервере
/// (core/api/admin_catalog.py): /admin/<section>/ и /admin/<section>/<id>/.
class AdminCatalogService {
  final Dio _dio = ApiClient.instance.dio;

  Future<AdminSection> load(String section) async {
    try {
      final r = await _dio.get('/admin/$section/');
      return AdminSection.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// [id] == null — создать, иначе изменить. [values] — только поля формы
  /// (без фото). [image] — новое фото; [removeImage] — убрать текущее.
  Future<void> save(String section, {int? id, required Map<String, String> values, XFile? image, bool removeImage = false}) async {
    final form = FormData.fromMap(values);
    if (image != null) {
      form.files.add(MapEntry('image', MultipartFile.fromBytes(await image.readAsBytes(), filename: image.name)));
    } else if (removeImage) {
      form.fields.add(const MapEntry('remove_image', 'true'));
    }
    try {
      if (id == null) {
        await _dio.post('/admin/$section/', data: form);
      } else {
        await _dio.patch('/admin/$section/$id/', data: form);
      }
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> delete(String section, int id) async {
    try {
      await _dio.delete('/admin/$section/$id/');
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}

class AdminSection {
  final List<AdminField> fields;
  final bool single; // одна запись (валюта) — без кнопки "Добавить"
  final List<AdminRecord> results;

  AdminSection({required this.fields, required this.single, required this.results});

  factory AdminSection.fromJson(Map<String, dynamic> j) => AdminSection(
        fields: (j['fields'] as List? ?? []).map((e) => AdminField.fromJson(e)).toList(),
        single: j['single'] == true,
        results: (j['results'] as List? ?? []).map((e) => AdminRecord.fromJson(e)).toList(),
      );
}

class AdminField {
  final String name;
  final String type; // text / number / image / choice
  final String labelRu;
  final String labelTk;
  final bool required;
  final List<({int id, String title})> choices;

  AdminField({
    required this.name,
    required this.type,
    required this.labelRu,
    required this.labelTk,
    required this.required,
    this.choices = const [],
  });

  String label(String lang) => lang == 'tk' && labelTk.isNotEmpty ? labelTk : labelRu;

  factory AdminField.fromJson(Map<String, dynamic> j) => AdminField(
        name: j['name'] ?? '',
        type: j['type'] ?? 'text',
        labelRu: j['label_ru'] ?? '',
        labelTk: j['label_tk'] ?? '',
        required: j['required'] == true,
        choices: [
          for (final c in (j['choices'] as List? ?? []))
            (id: (c['id'] as num).toInt(), title: '${c['title'] ?? ''}'),
        ],
      );
}

class AdminRecord {
  final int id;
  final String title;
  final String subtitle;
  final String? image;
  final Map<String, dynamic> values;

  AdminRecord({required this.id, required this.title, required this.subtitle, this.image, required this.values});

  factory AdminRecord.fromJson(Map<String, dynamic> j) => AdminRecord(
        id: (j['id'] as num).toInt(),
        title: '${j['title'] ?? ''}',
        subtitle: '${j['subtitle'] ?? ''}',
        image: j['image'],
        values: Map<String, dynamic>.from(j['values'] ?? const {}),
      );
}
