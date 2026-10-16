import 'dart:io' show Platform;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

/// Статистика приложения в Matomo на нашем сервере
/// (https://owadanexpress.com.tm/stats/). Работает без сервисов Google,
/// поэтому данные доходят и у клиентов без VPN.
///
/// - [screen] — просмотр экрана (как "просмотр страницы" на сайте);
/// - [event]  — действие: добавил в корзину, оформил заказ, поиск и т.п.
///
/// Ошибки отправки никогда не мешают работе приложения — просто пропускаются.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const _baseUrl = 'https://app.owadanexpress';
  static const _visitorKey = 'analytics_visitor_id';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));
  final _storage = const FlutterSecureStorage();
  final _random = Random.secure();

  String _language = 'ru';
  String _lastUrl = '';
  String? _visitorId;

  bool get _enabled => !kIsWeb && ApiConfig.matomoAppSiteId > 0;

  void setLanguage(String language) => _language = language;

  /// Постоянный анонимный ID устройства (16 hex-символов) — чтобы Matomo
  /// считал уникальных посетителей, а не каждый запуск как нового.
  Future<String> _getVisitorId() async {
    if (_visitorId != null) return _visitorId!;
    String? id;
    try {
      id = await _storage.read(key: _visitorKey);
    } catch (_) {}
    if (id == null || id.length != 16) {
      id = List.generate(16, (_) => _random.nextInt(16).toRadixString(16)).join();
      try {
        await _storage.write(key: _visitorKey, value: id);
      } catch (_) {}
    }
    return _visitorId = id;
  }

  /// По нему Matomo определяет устройство и ОС (отчёт "Устройства").
  String get _userAgent {
    if (Platform.isIOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS like Mac OS X) OwadanExpressApp/${ApiConfig.appVersion}';
    }
    return 'Mozilla/5.0 (Linux; Android ${Platform.operatingSystemVersion}) OwadanExpressApp/${ApiConfig.appVersion}';
  }

  String get _resolution {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      return '${size.width.round()}x${size.height.round()}';
    } catch (_) {
      return '';
    }
  }

  /// Просмотр экрана. [path] — "адрес" экрана в отчёте, например `/product/kurtka`.
  Future<void> screen(String path, {String? title}) {
    final params = <String, String>{'action_name': title ?? path};
    final referrer = _lastUrl;
    _lastUrl = path;
    if (referrer.isNotEmpty) params['urlref'] = '$_baseUrl$referrer';
    return _send(path, params);
  }

  /// Действие пользователя. Поиск попадает в отчёт "Поиск по сайту",
  /// остальное — в "События" (категория "app", действие = [name]).
  Future<void> event(String name, {Map<String, Object?> data = const {}}) {
    final path = _lastUrl.isEmpty ? '/' : _lastUrl;
    if (name == 'search' && data['query'] != null) {
      return _send(path, {'action_name': 'search', 'search': '${data['query']}'});
    }
    final label = data['product'] ?? data['method'] ?? data['query'];
    final value = data['total'] ?? data['quantity'];
    return _send(path, {
      'e_c': 'app',
      'e_a': name,
      if (label != null) 'e_n': '$label',
      if (value is num) 'e_v': '$value',
    });
  }

  Future<void> _send(String path, Map<String, String> extra) async {
    if (!_enabled) return;
    try {
      final params = <String, String>{
        'idsite': '${ApiConfig.matomoAppSiteId}',
        'rec': '1',
        'apiv': '1',
        'send_image': '0',
        'url': '$_baseUrl$path',
        '_id': await _getVisitorId(),
        'lang': _language,
        'res': _resolution,
        'ua': _userAgent,
        'rand': '${_random.nextInt(1 << 31)}',
        ...extra,
      };
      await _dio.get(
        '${ApiConfig.matomoUrl}/matomo.php',
        queryParameters: params,
        options: Options(headers: {'User-Agent': _userAgent}),
      );
    } catch (_) {
      // статистика не должна ломать приложение
    }
  }
}
