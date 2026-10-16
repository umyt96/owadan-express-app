import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

/// Проверяет, что пользователь авторизован. Если нет — открывает экран входа
/// и ждёт результата. Возвращает true, если в итоге пользователь авторизован
/// (либо уже был, либо только что вошёл/зарегистрировался).
///
/// Используется перед действиями, которым нужна авторизация (добавить в
/// корзину/избранное, оформить заказ, открыть профиль) — само по себе
/// просматривание каталога авторизации не требует.
Future<bool> ensureLoggedIn(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  if (auth.status == AuthStatus.authenticated) return true;

  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return result == true;
}
