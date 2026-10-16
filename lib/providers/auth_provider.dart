import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  String? errorMessage;
  bool isLoading = false;

  /// Вызывается один раз при старте приложения (см. SplashScreen).
  Future<void> checkAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      // Устройство могло остаться привязанным к прежнему аккаунту (выход в
      // старой версии приложения) — отвязываем, без ожидания.
      PushNotificationService.instance.unregisterToken();
      return;
    }
    try {
      currentUser = await _authService.me();
      status = AuthStatus.authenticated;
      PushNotificationService.instance.registerToken();
    } catch (_) {
      // Если токены удалены — сервер их отверг, значит действительно вышли.
      // Иначе это нет сети / сервер недоступен: остаёмся в аккаунте и
      // догружаем профиль позже.
      if (await _authService.isLoggedIn()) {
        status = AuthStatus.authenticated;
        _retryLoadUser();
      } else {
        status = AuthStatus.unauthenticated;
      }
    }
    notifyListeners();
  }

  Future<void> _retryLoadUser() async {
    for (var i = 0; i < 20 && currentUser == null; i++) {
      await Future.delayed(const Duration(seconds: 15));
      if (status != AuthStatus.authenticated) return;
      try {
        currentUser = await _authService.me();
        PushNotificationService.instance.registerToken();
        notifyListeners();
        return;
      } catch (_) {
        if (!await _authService.isLoggedIn()) {
          status = AuthStatus.unauthenticated;
          notifyListeners();
          return;
        }
      }
    }
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _authService.login(username: username, password: password);
      currentUser = await _authService.me();
      status = AuthStatus.authenticated;
      PushNotificationService.instance.registerToken();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
    String number = '',
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        number: number,
      );
      // Регистрация не выдаёт токены — сразу логинимся теми же данными.
      return await login(username, password);
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final success = await _authService.loginWithGoogle();
      if (!success) return false; // пользователь отменил выбор аккаунта
      if (kDebugMode) {
        debugPrint('\x1B[36m[GoogleAuth][profile] Loading user profile\x1B[0m');
      }
      currentUser = await _authService.me();
      if (kDebugMode) {
        debugPrint('\x1B[32m[GoogleAuth][profile] Profile loaded\x1B[0m');
      }
      status = AuthStatus.authenticated;
      PushNotificationService.instance.registerToken();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '\x1B[31m[GoogleAuth][provider] Login failed: ${e.runtimeType}\x1B[0m');
      }
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithYandex() => _loginWith(_authService.loginWithYandex);

  Future<bool> loginWithApple() => _loginWith(_authService.loginWithApple);

  /// Настроен ли на сервере вход через Apple (иначе кнопку не показываем).
  Future<bool> isAppleEnabled() => _authService.isAppleEnabled();

  Future<bool> _loginWith(Future<bool> Function() login) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final success = await login();
      if (!success) return false; // пользователь закрыл окно / нажал "Отмена"
      currentUser = await _authService.me();
      status = AuthStatus.authenticated;
      PushNotificationService.instance.registerToken();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Сначала отвязываем устройство — иначе уведомления аккаунта
    // продолжат приходить на этот телефон после выхода.
    await PushNotificationService.instance.unregisterToken();
    await _authService.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Обновляет данные пользователя в памяти (например, после редактирования профиля)
  /// и уведомляет все экраны, которые их показывают.
  void setCurrentUser(AppUser user) {
    currentUser = user;
    notifyListeners();
  }
}
