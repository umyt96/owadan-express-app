import 'package:dio/dio.dart';

import '../models/about_page.dart';
import '../models/contact_info.dart';
import 'api_client.dart';

class MiscService {
  final Dio _dio = ApiClient.instance.dio;
  static final Map<String, ContactInfo> _cachedContactInfo = {};
  static final Map<String, Future<ContactInfo>> _loadingContactInfo = {};

  ContactInfo? get cachedContactInfo =>
      _cachedContactInfo[ApiClient.instance.language];

  /// Reuse the startup request across the contact page and floating call button.
  Future<ContactInfo> getContactInfo({bool refresh = false}) {
    final language = ApiClient.instance.language;
    final pending = _loadingContactInfo[language];
    if (pending != null) return pending;
    final cached = _cachedContactInfo[language];
    if (!refresh && cached != null) {
      return Future.value(cached);
    }
    return _loadingContactInfo[language] = _loadContactInfo(language);
  }

  Future<ContactInfo> _loadContactInfo(String language) async {
    try {
      final response = await _dio.get('/contact-us/');
      final info = ContactInfo.fromJson(response.data);
      _cachedContactInfo[language] = info;
      return info;
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    } finally {
      _loadingContactInfo.remove(language);
    }
  }

  Future<List<AboutPage>> getAbout() async {
    try {
      final response = await _dio.get('/about/');
      final list = response.data as List;
      return list.map((e) => AboutPage.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Форма "Связаться с нами" — не требует авторизации.
  Future<void> sendContactMessage({
    required String name,
    required String contact,
    required String message,
  }) async {
    try {
      await _dio.post('/send-message/', data: {
        'title': name,
        'contact': contact,
        'message': message,
      });
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}
