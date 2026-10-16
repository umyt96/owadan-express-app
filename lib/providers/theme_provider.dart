import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../theme/app_theme.dart';

/// Дневной / ночной режим приложения. Выбор сохраняется и переживает
/// перезапуск; по умолчанию — как в настройках телефона.
class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _storageKey = 'app_theme_mode';
  final _storage = const FlutterSecureStorage();

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Реально активен ли сейчас тёмный режим (с учётом режима "как в системе").
  bool get isDark {
    if (_mode == ThemeMode.system) {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Режим "как в системе": пользователь сменил тему телефона.
  @override
  void didChangePlatformBrightness() {
    if (_mode == ThemeMode.system) _apply();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> load() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      _mode = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {}
    _apply();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    _apply();
    try {
      await _storage.write(key: _storageKey, value: mode.name);
    } catch (_) {}
  }

  void _apply() {
    AppColors.applyDark(isDark);
    notifyListeners();
  }
}
