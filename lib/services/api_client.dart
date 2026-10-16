import 'dart:async';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../l10n/app_strings.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

/// Эндпоинты, для которых НЕ подставляется access-токен
/// и на которых нельзя пытаться делать refresh при 401.
const _publicPaths = [
  '/auth/login/',
  '/auth/register/',
  '/auth/refresh/',
  '/auth/google/',
];

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['Accept-Language'] = _language;
        final isPublic = _publicPaths.any((p) => options.path.contains(p));
        if (!isPublic) {
          final token = await TokenStorage.instance.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isPublic =
            _publicPaths.any((p) => error.requestOptions.path.contains(p));

        if (error.response?.statusCode == 401 && !isPublic) {
          final refreshed = await _refreshToken();
          // Токены удаляются только в _refreshToken, если сервер сказал, что
          // refresh-токен недействителен. При плохой сети — не разлогиниваем.
          if (refreshed) {
            try {
              final response = await _retry(error.requestOptions);
              return handler.resolve(response);
            } catch (_) {
              // не получилось повторить запрос — отдаём исходную ошибку ниже
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  String _language = 'ru';
  String get language => _language;
  void setLanguage(String language) => _language = language;

  Dio get dio => _dio;

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  /// Обновляет access-токен по refresh-токену.
  /// Если несколько запросов словили 401 одновременно — реально
  /// обновление токена выполнится один раз, остальные дождутся результата.
  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      return _refreshCompleter!.future;
    }
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refresh = await TokenStorage.instance.refreshToken;
      if (refresh == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

      // Отдельный Dio без interceptor'ов, чтобы не зациклиться.
      final plainDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      final response = await plainDio.post('/auth/refresh/', data: {
        'refresh': refresh,
      });

      final newAccess = response.data['access'] as String;
      final newRefresh = response.data['refresh'] as String?;

      if (newRefresh != null) {
        await TokenStorage.instance
            .saveTokens(access: newAccess, refresh: newRefresh);
      } else {
        await TokenStorage.instance.saveAccessToken(newAccess);
      }

      _refreshCompleter!.complete(true);
      return true;
    } on DioException catch (e) {
      // 401/400 — refresh-токен истёк или недействителен: только тогда выходим.
      // Нет интернета, таймаут, 5xx — токены оставляем, пользователь остаётся в аккаунте.
      final code = e.response?.statusCode;
      if (code == 401 || code == 400) {
        await TokenStorage.instance.clear();
      }
      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await TokenStorage.instance.accessToken;
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Превращает DioException в понятное сообщение для показа пользователю.
  ApiException toApiException(DioException e) {
    final data = e.response?.data;
    String message = AppStrings.t('network_error', _language);

    if (data is Map && data['detail'] != null) {
      message = data['detail'].toString();
    } else if (data is Map && data.isNotEmpty) {
      // ошибки валидации DRF вида {"field": ["сообщение"]}
      final firstKey = data.keys.first;
      final firstValue = data[firstKey];
      message = firstValue is List
          ? firstValue.first.toString()
          : firstValue.toString();
    }

    return ApiException(message,
        statusCode: e.response?.statusCode, data: data);
  }
}
