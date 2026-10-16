import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/misc_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

/// Заставка при запуске: фирменный градиент, логотип плавно появляется с
/// лёгким увеличением, под ним — мягкий индикатор загрузки. Показывается
/// минимум 3 секунды; за это время параллельно проверяются сохранённые токены
/// и язык, а затем открывается главный экран с плавным переходом.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _minDuration = Duration(seconds: 3);

  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _footerOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _logoOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack)),
    );
    _footerOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeIn));
    _controller.forward();
    _init();
  }

  Future<void> _init() async {
    // Make contact details available by the time the user opens the page.
    // A contact endpoint failure must not delay app startup.
    final localeLoad = context.read<LocaleProvider>().load();
    unawaited(localeLoad.then<void>((_) async {
      try {
        await MiscService().getContactInfo();
      } catch (_) {}
    }));
    await Future.wait([
      context.read<AuthProvider>().checkAuth(),
      localeLoad,
      Future.delayed(_minDuration),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const MainNavigationScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
    // Приложение открыто нажатием на уведомление — теперь, когда главный
    // экран на месте, открываем нужный экран поверх него.
    PushNotificationService.instance.markAppReady();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      // Цвет под градиентом — чтобы ни на мгновение не мелькал белый фон.
      backgroundColor: AppColors.gradientEnd,
      body: Container(
        // Без явных размеров Container сжимался до ширины логотипа, и
        // справа оставалась белая полоса — растягиваем на весь экран.
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.12),
                          blurRadius: 80,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/branding/splash_logo.png',
                      width: width * 0.62,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _footerOpacity,
                child: const Column(
                  children: [
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white70),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'owadanexpress.com.tm',
                      style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
