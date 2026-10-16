import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';

/// Обновление из Google Play прямо в приложении (In-App Updates).
///
/// Если в Play вышла новая версия, Google показывает своё окно
/// "Доступно обновление — Обновить / Нет, спасибо". При согласии обновление
/// скачивается в фоне, пользователь продолжает пользоваться приложением, а
/// потом внизу появляется "Обновление загружено — Перезапустить".
///
/// Работает только у приложения, установленного из Google Play. В сборке с
/// компьютера (flutter run) проверка просто ничего не делает.
class AppUpdateService {
  AppUpdateService._();

  static bool _checked = false;

  /// Вызывается один раз после запуска (см. MainNavigationScreen).
  static Future<void> checkForUpdate(BuildContext context) async {
    if (_checked || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _checked = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable || !info.flexibleUpdateAllowed) {
        return;
      }
      // Окно Google "Обновить / Нет, спасибо"; future завершается, когда
      // пользователь согласился и обновление скачано.
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result != AppUpdateResult.success || !context.mounted) return;

      final locale = context.read<LocaleProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(days: 1), // висит, пока не нажмут
          content: Text(locale.t('update_downloaded')),
          action: SnackBarAction(
            label: locale.t('update_restart'),
            onPressed: () => InAppUpdate.completeFlexibleUpdate(),
          ),
        ),
      );
    } catch (_) {
      // Не из Google Play, нет сети и т.п. — просто работаем дальше.
    }
  }
}
