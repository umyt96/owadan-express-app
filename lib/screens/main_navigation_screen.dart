import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/app_update_service.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../widgets/contact_fab.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/connection_gate.dart';
import '../services/analytics_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _refreshGeneration = 0;

  @override
  void initState() {
    super.initState();
    // Статистика: открытие приложения и переходы между вкладками.
    _trackTab();
    currentTabIndex.addListener(_trackTab);
    connectionRestoredTick.addListener(_refreshTabs);
    // Новая версия в Google Play — предложить обновиться (Обновить / Позже).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthProvider>().status == AuthStatus.authenticated) {
        context.read<CartProvider>().loadCart();
      }
      AppUpdateService.checkForUpdate(context);
    });
  }

  static const _tabPaths = ['/', '/categories', '/cart', '/favorites', '/profile'];

  void _trackTab() {
    final i = currentTabIndex.value;
    if (i >= 0 && i < _tabPaths.length) {
      AnalyticsService.instance.screen(_tabPaths[i]);
    }
  }

  void _refreshTabs() {
    if (mounted) setState(() => _refreshGeneration++);
  }

  @override
  void dispose() {
    currentTabIndex.removeListener(_trackTab);
    connectionRestoredTick.removeListener(_refreshTabs);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: currentTabIndex,
      builder: (context, index, _) {
        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(index: index, children: [
                HomeScreen(key: ValueKey('home-$_refreshGeneration')),
                CategoriesScreen(key: ValueKey('categories-$_refreshGeneration')),
                CartScreen(key: ValueKey('cart-$_refreshGeneration')),
                FavoritesScreen(key: ValueKey('favorites-$_refreshGeneration')),
                ProfileScreen(key: ValueKey('profile-$_refreshGeneration')),
              ]),
              const ContactFab(),
            ],
          ),
          bottomNavigationBar: AppBottomNav(currentIndex: index),
        );
      },
    );
  }
}
