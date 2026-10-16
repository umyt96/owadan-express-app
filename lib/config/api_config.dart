class ApiConfig {
  static const String baseUrl = 'https://owadanexpress.com.tm/api/v1';

  // Для локальной отладки на Android-эмуляторе (пока меняете бэкенд у себя на компьютере):
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Для запуска на реальном телефоне в той же Wi-Fi сети, что и компьютер:
  // static const String baseUrl = 'http://192.168.1.50:8000/api/v1';

  /// Web OAuth Client ID ("for django") из Google Cloud проекта 388147779780 —
  /// тот же, что в settings.py сайта (сервер проверяет aud ID-токена именно
  /// по нему). Android-клиенты с SHA-1 подписи (Play 97:6C, upload 37:8E)
  /// заведены в этом же проекте. НЕ брать ID из google-services.json
  /// (проект Firebase 626558989499) — там нет наших SHA-1, будет ошибка 10.
  static const String googleWebClientId =
      '388147779780-ceniic71fnk5rbji41p1t6lrphd4ivn0.apps.googleusercontent.com';

  /// Статистика Matomo на нашем сервере (см. инструкцию по установке).
  static const String matomoUrl = 'https://owadanexpress.com.tm/stats';

  /// ID сайта "Приложение" в Matomo (Администрирование → Сайты → Управление,
  /// колонка ID). Пока 0 — статистика просто не отправляется.
  static const int matomoAppSiteId = 2;

  /// Версия для отчётов (держите в соответствии с version в pubspec.yaml).
  static const String appVersion = '5.0';
}
