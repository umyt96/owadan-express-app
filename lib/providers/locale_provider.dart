import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/push_notification_service.dart';
import '../services/analytics_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const _storageKey = 'app_language';
  final _storage = const FlutterSecureStorage();

  String _language = 'ru';
  String get language => _language;

  /// Загружает сохранённый выбор языка (вызывается один раз при старте).
  Future<void> load() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'ru' || saved == 'tk' || saved == 'en') {
        _language = saved!;
        ApiClient.instance.setLanguage(_language);
        notifyListeners();
      }
      // Сервер поддерживает русские и туркменские push-уведомления.
      PushNotificationService.instance.updateLanguage(_pushLanguage);
    } catch (_) {
      // используем русский по умолчанию, если не удалось прочитать
    }
  }

  Future<void> setLanguage(String lang) async {
    if (lang != 'ru' && lang != 'tk' && lang != 'en') return;
    _language = lang;
    ApiClient.instance.setLanguage(lang);
    notifyListeners();
    PushNotificationService.instance.updateLanguage(_pushLanguage);
    try {
      await _storage.write(key: _storageKey, value: lang);
    } catch (_) {
      // не критично, если сохранить не удалось — выбор просто не переживёт перезапуск
    }
  }

  /// Короткий помощник для перевода строк интерфейса: `context.watch<LocaleProvider>().t('key')`.
  String t(String key) => AppStrings.t(key, _language);

  String days(int count) => AppStrings.days(count, _language);

  // Сервер пока отправляет push только на русском и туркменском.
  String get _pushLanguage => _language == 'en' ? 'ru' : _language;

  @override
  void notifyListeners() {
    AnalyticsService.instance.setLanguage(_language);
    super.notifyListeners();
  }
}
