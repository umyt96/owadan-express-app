import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/manage_models.dart';
import 'api_client.dart';

/// Раздел "Товары": добавление/изменение — персонал, удаление — суперпользователь.
class ManageService {
  final Dio _dio = ApiClient.instance.dio;

  Future<ManageMeta> getMeta() async {
    try {
      final r = await _dio.get('/manage/meta/');
      return ManageMeta.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// [filter]: 'all' / 'hidden' (скрытые) / 'out' (нет на складе — количество 0).
  /// [counts] — сколько товаров в каждом фильтре (для чисел на кнопках);
  /// старый сервер без фильтров вернёт пустой словарь.
  Future<({List<ManageItem> items, bool hasMore, int count, Map<String, int> counts})> getItems(
      {int page = 1, String search = '', String filter = 'all'}) async {
    try {
      final r = await _dio.get('/manage/items/', queryParameters: {
        'page': page,
        if (search.isNotEmpty) 'search': search,
        if (filter != 'all') 'filter': filter,
      });
      final list = (r.data['results'] as List).map((e) => ManageItem.fromJson(e)).toList();
      final counts = <String, int>{
        for (final e in ((r.data['counts'] as Map?) ?? const {}).entries) '${e.key}': (e.value as num).toInt(),
      };
      return (items: list, hasMore: r.data['next'] != null, count: (r.data['count'] ?? 0) as int, counts: counts);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<ManageItemDetail> getItem(int id) async {
    try {
      final r = await _dio.get('/manage/items/$id/');
      return ManageItemDetail.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Создать ([id] == null) или изменить товар. [fields] — только изменённые
  /// поля (при изменении), фото — файлами. Через bytes — работает и на Web.
  Future<ManageItemDetail> save({
    int? id,
    required Map<String, dynamic> fields,
    XFile? mainImage,
    List<XFile> extraImages = const [],
    List<int> removeImageIds = const [],
    void Function(double progress)? onProgress,
  }) async {
    Future<MultipartFile> part(XFile f) async =>
        MultipartFile.fromBytes(await f.readAsBytes(), filename: f.name);

    final form = FormData();
    fields.forEach((key, value) {
      if (value == null) {
        form.fields.add(MapEntry(key, ''));
      } else if (value is List) {
        form.fields.add(MapEntry(key, value.join(',')));
      } else {
        form.fields.add(MapEntry(key, value.toString()));
      }
    });
    if (removeImageIds.isNotEmpty) {
      form.fields.add(MapEntry('remove_image_ids', removeImageIds.join(',')));
    }
    if (mainImage != null) form.files.add(MapEntry('image', await part(mainImage)));
    for (final f in extraImages) {
      form.files.add(MapEntry('extra_images', await part(f)));
    }

    try {
      final r = id == null
          ? await _dio.post('/manage/items/', data: form,
              onSendProgress: (s, t) => t > 0 ? onProgress?.call(s / t) : null)
          : await _dio.patch('/manage/items/$id/', data: form,
              onSendProgress: (s, t) => t > 0 ? onProgress?.call(s / t) : null);
      return ManageItemDetail.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/manage/items/$id/');
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<List<RefOption>> getSizes({String search = ''}) async {
    try {
      final r = await _dio.get('/manage/sizes/', queryParameters: {if (search.isNotEmpty) 'search': search});
      return (r.data as List).map((e) => RefOption.size(e)).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<RefOption> createSize(String title) async {
    try {
      final r = await _dio.post('/manage/sizes/', data: {'title': title});
      return RefOption.size(r.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<List<RefOption>> getColors({String search = ''}) async {
    try {
      final r = await _dio.get('/manage/colors/', queryParameters: {if (search.isNotEmpty) 'search': search});
      return (r.data as List).map((e) => RefOption.color(e)).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<RefOption> createColor(String titleRu, String titleTk) async {
    try {
      final r = await _dio.post('/manage/colors/', data: {'title_ru': titleRu, 'title_tk': titleTk});
      return RefOption.color(r.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}
