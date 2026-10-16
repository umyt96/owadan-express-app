import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/locale_provider.dart';

import '../screens/admin_messages_screen.dart';
import '../screens/admin_orders_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/product_detail_screen.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'checkout_service.dart' show ordersChangedTick;

/// Обработчик фоновых push-уведомлений — ОБЯЗАТЕЛЬНО top-level функция
/// (не метод класса), это требование package:firebase_messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Система сама показывает уведомление из RemoteMessage.notification,
  // когда приложение свёрнуто/закрыто — здесь ничего дополнительно делать
  // не нужно, разве что в будущем захотите что-то логировать/сохранять.
}

/// Push-уведомления через Firebase Cloud Messaging: получение токена
/// устройства, регистрация на бэкенде, показ уведомлений, пока приложение
/// открыто (foreground — их система не показывает сама, только фоновые).
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  // Геттер, а не final-поле: final-поле вычислилось бы сразу при первом
  // обращении к PushNotificationService.instance (даже на Web, где Firebase
  // не инициализирован) и падало бы с FirebaseException раньше, чем успела
  // бы сработать проверка kIsWeb внутри методов ниже.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Язык приложения ('ru' / 'tk') — сервер шлёт уведомления на этом языке.
  /// Обновляется из LocaleProvider (при запуске и при смене языка).
  String _language = 'ru';
  String? _registeredToken;
  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Вызывается из LocaleProvider. Если устройство уже зарегистрировано —
  /// сразу сообщаем серверу новый язык.
  Future<void> updateLanguage(String language) async {
    if (_language == language) return;
    _language = language;
    if (_initialized) _subscribeLanguageTopic();
    final token = _registeredToken;
    if (!kIsWeb && token != null) await _sendTokenToBackend(token);
  }

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (_isIOS) {
      // iOS presents the remote notification itself while the app is open.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        final parts = payload.split('|');
        if (parts.length < 2) return;
        _navigateForMessage(
            RemoteMessage(data: {'type': parts[0], 'slug': parts[1]}));
      },
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'default_channel',
              'Owadan Express',
              description: 'Order and account notifications',
              importance: Importance.high,
            ),
          );
    }

    // Foreground: FCM не показывает системное уведомление сам — показываем
    // его через flutter_local_notifications, чтобы пользователь видел
    // уведомление, даже когда приложение открыто.
    FirebaseMessaging.onMessage.listen((message) {
      // Новый заказ, пока приложение открыто — обновляем списки заказов.
      final pushType = message.data['type'];
      if (pushType == 'new_order' || pushType == 'order_delivered') {
        ordersChangedTick.value++;
      }
      final notification = message.notification;
      if (notification == null) return;
      if (_isIOS) return; // iOS foreground presentation is enabled above.
      final type = message.data['type'] ?? '';
      final slug = message.data['slug'] ?? message.data['message_id'] ?? '';
      _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Owadan Express',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: '$type|$slug',
      );
    });

    // Нажатие на уведомление, когда приложение было свёрнуто (не закрыто
    // полностью) — ведём на нужный экран сразу.
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateForMessage);

    // Token refresh must be observed even when the user is signed out.
    _messaging.onTokenRefresh.listen((token) {
      _logToken('FCM', token);
      unawaited(_sendTokenToBackend(token));
    });
    // Permission dialogs must not block the first Flutter frame. APNs token
    // registration may complete only after the user answers the dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_requestPermissionAndLogStartupTokens());
    });
  }

  Future<void> _requestPermissionAndLogStartupTokens() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] Permission request failed: $e');
    }
    await _logStartupTokens();
  }

  Future<void> _logStartupTokens() async {
    if (_isIOS) {
      String? apnsToken;
      for (var attempt = 0; attempt < 10; attempt++) {
        try {
          apnsToken = await _messaging.getAPNSToken();
        } catch (e) {
          if (kDebugMode) debugPrint('[Push] APNs token error: $e');
          return;
        }
        if (apnsToken != null) break;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      _logToken('APNs', apnsToken);
      if (apnsToken == null) {
        if (kDebugMode) {
          debugPrint('[Push] FCM token pending: APNs token unavailable');
        }
        return;
      }
    }

    try {
      final token = await _messaging.getToken();
      _logToken('FCM', token);
      if (token != null) {
        await _subscribeLanguageTopic();
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] FCM token error: $e');
    }
  }

  void _logToken(String type, String? token) {
    if (kDebugMode) debugPrint('[Push] $type token: ${token ?? 'unavailable'}');
  }

  /// Вызывается один раз после первого кадра приложения (см. main.dart).
  /// Запоминает navigatorKey для последующих нажатий на уведомления и
  /// проверяет, не был ли сам запуск приложения вызван нажатием на push
  /// (приложение было полностью закрыто) — если да, сразу переходим на
  /// нужный экран.
  Future<void> handlePendingNavigation(
      GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    if (kIsWeb) return;
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _navigateForMessage(initialMessage);
    }
  }

  // Пока идёт заставка, переход откладывается: заставка в конце заменяет
  // верхний экран на главный (pushReplacement) и закрыла бы открытый по
  // уведомлению экран — из-за этого раньше сразу выкидывало на главную.
  bool _appReady = false;
  RemoteMessage? _pendingMessage;

  /// Вызывается заставкой сразу после перехода на главный экран.
  void markAppReady() {
    _appReady = true;
    final pending = _pendingMessage;
    _pendingMessage = null;
    if (pending != null) _navigateForMessage(pending);
  }

  void _navigateForMessage(RemoteMessage message) {
    if (!_appReady) {
      _pendingMessage = message;
      return;
    }
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    final type = message.data['type'];
    if (type == 'new_item') {
      final slug = message.data['slug'];
      if (slug != null) {
        navigator.push(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: slug)));
      }
    } else if (type == 'admin_reply') {
      navigator.push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
    } else if (type == 'user_message') {
      // Суперпользователю: клиент написал администратору.
      navigator
          .push(MaterialPageRoute(builder: (_) => const AdminMessagesScreen()));
    } else if (type == 'new_order') {
      // Суперпользователю: оформлен новый заказ.
      navigator
          .push(MaterialPageRoute(builder: (_) => const AdminOrdersScreen()));
    } else if (type == 'order_delivered') {
      // Клиенту: заказ доставлен — открываем историю заказов.
      navigator.push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
    } else if (type == 'app_update') {
      // Всем: вышла новая версия — "Обновить" (Google Play) / "Позже".
      _showUpdateDialog(navigator.context);
    }
  }

  void _showUpdateDialog(BuildContext context) {
    final locale = context.read<LocaleProvider>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedSystemUpdate01, size: 40),
        title: Text(locale.t('update_available_title')),
        content: Text(locale.t('update_available_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(locale.t('update_later')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openPlayStore();
            },
            child: Text(locale.t('update_now')),
          ),
        ],
      ),
    );
  }

  Future<void> _openPlayStore() async {
    const id = 'tm.com.owadanexpress.twa';
    // Сначала приложение Google Play, если его нет — страница в браузере.
    final opened = await launchUrl(Uri.parse('market://details?id=$id'),
            mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!opened) {
      await launchUrl(
          Uri.parse('https://play.google.com/store/apps/details?id=$id'),
          mode: LaunchMode.externalApplication);
    }
  }

  /// Получает FCM-токен устройства и отправляет на бэкенд — вызывать после
  /// успешного входа/регистрации (см. AuthProvider), а не раньше, так как
  /// эндпоинт требует авторизации.
  Future<void> registerToken() async {
    if (kIsWeb) return; // Firebase не инициализирован на Web — см. main.dart
    try {
      if (_isIOS && await _messaging.getAPNSToken() == null) return;
      final token = await _messaging.getToken();
      if (token == null) return;
      _logToken('FCM', token);
      await _subscribeLanguageTopic();
      await _sendTokenToBackend(token);
    } catch (e) {
      if (kDebugMode) {
        // На эмуляторах без Google Play Services getToken() может упасть —
        // не роняем вход пользователя из-за этого.
        debugPrint('Push notification token error: $e');
      }
    }
  }

  /// Выход из аккаунта (или приложение запущено без входа): отвязываем
  /// устройство от аккаунта на сервере, чтобы уведомления прежнего аккаунта
  /// (например, суперпользователю о заказах) сюда больше не шли.
  /// Сам FCM-токен НЕ удаляем — на нём держится подписка на общие темы
  /// (уведомление о новой версии приходит и без входа). Если сейчас нет
  /// сети — повторится при следующем запуске без входа.
  Future<void> unregisterToken() async {
    if (kIsWeb) return;
    try {
      final token = _registeredToken ?? await _messaging.getToken();
      _registeredToken = null;
      if (token != null) {
        await ApiClient.instance.dio
            .post('/devices/unregister/', data: {'token': token});
      }
    } catch (_) {}
  }

  // Общие темы для всех установок (без входа): all_users_ru / all_users_tk —
  // по языку приложения. На них сервер шлёт "Вышло обновление"
  // (python manage.py send_update_push).
  static const _topicPrefix = 'all_users_';
  String? _subscribedTopicLanguage;

  Future<void> _subscribeLanguageTopic() async {
    if (kIsWeb || _subscribedTopicLanguage == _language) return;
    try {
      final old = _subscribedTopicLanguage;
      await _messaging.subscribeToTopic('$_topicPrefix$_language');
      if (old != null) {
        await _messaging.unsubscribeFromTopic('$_topicPrefix$old');
      }
      _subscribedTopicLanguage = _language;
    } catch (_) {
      // Нет сети / Google Play Services — попробуем при следующем запуске.
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    // После выхода (токены входа удалены) не привязываем устройство снова,
    // например при onTokenRefresh.
    if (await TokenStorage.instance.accessToken == null) return;
    try {
      final sentLanguage = _language;
      await ApiClient.instance.dio.post('/devices/register/', data: {
        'token': token,
        'language': sentLanguage,
      });
      _registeredToken = token;
      // Язык успел смениться, пока шёл запрос (например, при запуске язык
      // загружается параллельно с проверкой входа) — отправляем актуальный.
      if (_language != sentLanguage) {
        await ApiClient.instance.dio.post('/devices/register/', data: {
          'token': token,
          'language': _language,
        });
      }
    } on DioException catch (_) {
      // Не критично для работы приложения — просто не будет push на этом
      // устройстве, пока не удастся зарегистрировать токен в следующий раз.
    }
  }
}
