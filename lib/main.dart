import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_reveal.dart';
import 'utils/system_ui_manager.dart';
import 'widgets/connection_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await SystemUiManager().start();
  }
  // На Web google-services.json не работает — там Firebase нужно
  // настраивать отдельно (FlutterFire CLI/firebase_options.dart). Так как
  // push-уведомления нужны на Android и iOS; на Web просто пропускаем
  // инициализацию Firebase, чтобы не падать при тестировании в браузере.
  if (!kIsWeb) {
    await Firebase.initializeApp();
    await PushNotificationService.instance.init();
  }
  // Тему загружаем ДО запуска, чтобы при старте не мелькал не тот режим.
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  runApp(OwadanExpressApp(themeProvider: themeProvider));
}

/// Общий ключ навигатора — через него push-уведомления открывают нужный
/// экран (товар/сообщения) из любого места в приложении, не завися от
/// того, какой BuildContext был активен в момент нажатия на уведомление.
final navigatorKey = GlobalKey<NavigatorState>();

class OwadanExpressApp extends StatefulWidget {
  final ThemeProvider themeProvider;

  const OwadanExpressApp({super.key, required this.themeProvider});

  @override
  State<OwadanExpressApp> createState() => _OwadanExpressAppState();
}

class _OwadanExpressAppState extends State<OwadanExpressApp> {
  @override
  void initState() {
    super.initState();
    widget.themeProvider.addListener(_onThemeChanged);
    // Если приложение было открыто нажатием на push (из свёрнутого состояния
    // или запущено заново нажатием на уведомление) — переходим на нужный
    // экран сразу после первого кадра.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.handlePendingNavigation(navigatorKey);
    });
  }

  @override
  void dispose() {
    widget.themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  /// Часть цветов (текст, карточки) берётся из AppColors напрямую, а не из
  /// Theme.of(context) — такие виджеты сами не узнают о смене темы. Поэтому
  /// после переключения помечаем всё дерево для перерисовки.
  void _onThemeChanged() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void rebuild(Element el) {
        el.markNeedsBuild();
        el.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) => MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Owadan Express',
          debugShowCheckedModeBanner: false,
          locale: Locale(locale.language == 'tk' ? 'en' : locale.language),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('ru'), Locale('en')],
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: widget.themeProvider.mode,
          home: const SplashScreen(),
          // Переход темы ведёт ThemeReveal (снимок старого экрана уезжает).
          themeAnimationDuration: Duration.zero,
          builder: (context, child) => ThemeReveal(
            child: ConnectionGate(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
