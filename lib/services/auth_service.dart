import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/api_config.dart';
import '../l10n/app_strings.dart';
import '../models/user.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;
  String _t(String key) => AppStrings.t(key, ApiClient.instance.language);

  void _googleLog(String step, String message, {String level = 'info'}) {
    if (!kDebugMode) return;
    final color = switch (level) {
      'success' => '\x1B[32m',
      'warning' => '\x1B[33m',
      'error' => '\x1B[31m',
      _ => '\x1B[36m',
    };
    debugPrint('$color[GoogleAuth][$step] $message\x1B[0m');
  }

  // Web Client ID должен соответствовать Android OAuth-клиенту в том же
  // Google Cloud проекте. Бэкенд также должен принимать его как audience.
  // Создаётся лениво (а не в момент конструктора AuthService), чтобы ошибка
  // инициализации плагина на вебе (например, отсутствующий meta-тег
  // google-signin-client_id в web/index.html) не роняла всё приложение при
  // старте, а проявлялась только в момент реальной попытки входа через Google.
  //
  // На Web пакет google_sign_in_web НЕ поддерживает параметр serverClientId
  // (падает с "serverClientId is not supported on Web") — там используется
  // только clientId из meta-тега google-signin-client_id в web/index.html,
  // и id_token уже выпускается с тем же Web Client ID, так что для бэкенда
  // разницы нет. Поэтому передаём serverClientId только на Android/iOS.
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn => _googleSignInInstance ??= GoogleSignIn(
        serverClientId: kIsWeb ? null : ApiConfig.googleWebClientId,
        scopes: ['email', 'profile'],
      );

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
    String number = '',
  }) async {
    try {
      await _dio.post('/auth/register/', data: {
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'number': number,
      });
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> login(
      {required String username, required String password}) async {
    try {
      final response = await _dio.post('/auth/login/', data: {
        'username': username,
        'password': password,
      });
      await TokenStorage.instance.saveTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Открывает системный выбор Google-аккаунта и логинит через бэкенд.
  /// Возвращает false, если пользователь закрыл окно выбора аккаунта (не ошибка).
  Future<bool> loginWithGoogle() async {
    var step = 'account';
    try {
      _googleLog(step, 'Opening Google account picker');
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _googleLog(
            step, 'No account returned (cancelled or Google configuration)',
            level: 'warning');
        return false;
      }
      _googleLog(step, 'Account selected', level: 'success');

      step = 'id-token';
      _googleLog(step, 'Requesting ID token');
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _googleLog(step, 'Google returned no ID token', level: 'error');
        throw ApiException(_t('google_no_token'));
      }
      _googleLog(step, 'ID token received', level: 'success');

      step = 'backend';
      _googleLog(step, 'Sending ID token to /auth/google/');
      final response =
          await _dio.post('/auth/google/', data: {'id_token': idToken});
      _googleLog(step, 'HTTP ${response.statusCode}', level: 'success');

      step = 'token-storage';
      await TokenStorage.instance.saveTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );
      _googleLog(step, 'Session tokens saved', level: 'success');
      return true;
    } on DioException catch (e) {
      _googleLog(step,
          'HTTP ${e.response?.statusCode ?? 'none'}, Dio type: ${e.type.name}',
          level: 'error');
      throw ApiClient.instance.toApiException(e);
    } on PlatformException catch (e) {
      _googleLog(
          step, 'Platform code: ${e.code}; message: ${e.message ?? 'none'}',
          level: 'error');
      // Ошибка самого Google на телефоне (до сервера не дошло).
      // ApiException: 10 — подпись приложения (SHA-1) или пакет не совпадают
      // с Android-клиентом в Google Cloud; 7 — нет сети; 12500 — настройки.
      final details = '${e.code} ${e.message ?? ''}';
      // В релизной сборке имена классов сжаты (R8): вместо
      // "ApiException: 10:" приходит, например, "s0.d: 10: " — берём число
      // после двоеточия в любом случае.
      final code = RegExp(r':\s*(\d+)\s*:').firstMatch(details)?.group(1);
      final hint = switch (code) {
        '7' => _t('google_no_connection'),
        '10' => _t('google_not_configured'),
        '12500' => _t('google_unavailable'),
        _ => _t('google_sign_in_failed'),
      };
      throw ApiException('$hint (${_t('auth_error_code')}: ${code ?? e.code})');
    } catch (e) {
      _googleLog(step, 'Unexpected ${e.runtimeType}', level: 'error');
      rethrow;
    }
  }

  /// Вход через Яндекс ID.
  Future<bool> loginWithYandex() => _loginViaServer('yandex', _t('yandex'));

  /// Вход через Apple ID.
  Future<bool> loginWithApple() => _loginViaServer('apple', 'Apple');

  /// Настроен ли вход через Apple на сервере (без ключей Apple кнопку не показываем).
  Future<bool> isAppleEnabled() async {
    try {
      final r = await _dio.get('/auth/apple/status/');
      return r.data['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Вход через Яндекс/Apple: открываем вход во вкладке браузера через наш
  /// сервер (секреты только там), сервер возвращает в приложение по ссылке
  /// owadanexpress://<provider>-auth?key=..., по ключу забираем токены.
  /// Возвращает false, если пользователь закрыл окно или нажал "Отмена".
  Future<bool> _loginViaServer(String provider, String name) async {
    final String result;
    try {
      // Веб-версия не принимает owadanexpress:// — сервер вернёт на её
      // страницу web/auth.html, а та передаст результат обратно в приложение.
      final start =
          Uri.parse('${ApiConfig.baseUrl}/auth/$provider/start/').replace(
        queryParameters:
            kIsWeb ? {'return': '${Uri.base.origin}/auth.html'} : null,
      );
      result = await FlutterWebAuth2.authenticate(
        url: start.toString(),
        callbackUrlScheme: 'owadanexpress',
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') return false;
      throw ApiException(_t('auth_open_failed').replaceAll('{provider}', name));
    }

    final params = Uri.parse(result).queryParameters;
    final error = params['error'];
    if (error == 'cancelled') return false;
    if (error != null) {
      throw ApiException(
          _t(error == 'no_email' ? 'auth_no_email' : 'auth_provider_failed')
              .replaceAll('{provider}', name));
    }

    try {
      final response = await _dio
          .post('/auth/$provider/exchange/', data: {'key': params['key']});
      await TokenStorage.instance.saveTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );
      return true;
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clear();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // не критично, если это не удалось (например, вход был не через Google)
    }
  }

  /// "Забыли пароль?" — сервер отправляет на почту ссылку для сброса пароля
  /// (тот же механизм, что на сайте).
  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post('/auth/password-reset/', data: {'email': email});
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/change-password/', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<bool> isLoggedIn() async {
    return await TokenStorage.instance.accessToken != null;
  }

  Future<AppUser> me() async {
    try {
      final response = await _dio.get('/auth/me/');
      return AppUser.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<AppUser> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? number,
  }) async {
    try {
      final response = await _dio.patch('/auth/me/', data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (number != null) 'number': number,
      });
      return AppUser.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}
