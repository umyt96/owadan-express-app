import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'cart_fly_animation.dart';

/// Shared tab selection also lets a pushed screen return to a root tab.
final ValueNotifier<int> currentTabIndex = ValueNotifier(0);

/// Нижнее меню: градиентная "капсула" скользит под активной вкладкой
/// (двигается только transform — без пересчёта layout) и "всплывает" с
/// небольшим перелётом при посадке; иконка пружинит и белеет.
class AppBottomNav extends StatefulWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();

  static const _height = 64.0;
  static const _margin = 6.0;

  static const _tabs = [
    (HugeIcons.strokeRoundedHome01, 'nav_home'),
    (HugeIcons.strokeRoundedGridView, 'nav_categories'),
    (HugeIcons.strokeRoundedShoppingBag01, 'nav_cart'),
    (HugeIcons.strokeRoundedFavourite, 'nav_favorites'),
    (HugeIcons.strokeRoundedUserCircle, 'nav_profile'),
  ];
}

class _AppBottomNavState extends State<AppBottomNav> {
  static const _height = AppBottomNav._height;
  static const _margin = AppBottomNav._margin;
  static const _tabs = AppBottomNav._tabs;

  /// Метка значка корзины: сюда прилетает фото товара при добавлении.
  final _cartIconKey = GlobalKey();

  int get currentIndex => widget.currentIndex;

  @override
  void initState() {
    super.initState();
    CartFlyAnimation.register(_cartIconKey);
  }

  @override
  void dispose() {
    CartFlyAnimation.unregister(_cartIconKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final locale = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: _height,
          child: Padding(
            padding: const EdgeInsets.all(_margin),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _tabs.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      width: itemWidth,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: itemWidth * currentIndex),
                        duration: AppMotion.duration(context, const Duration(milliseconds: 420)),
                        curve: Curves.easeOutBack,
                        builder: (context, dx, child) => Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        ),
                        // Ключ по индексу перезапускает "всплытие" при каждой
                        // посадке на новую вкладку.
                        child: RepaintBoundary(
                          child: _Highlight(key: ValueKey(currentIndex)),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < _tabs.length; i++)
                          Expanded(
                            child: _NavItem(
                              icon: _tabs[i].$1,
                              label: locale.t(_tabs[i].$2),
                              active: i == currentIndex,
                              badgeCount: i == 2 ? cartCount : 0,
                              iconKey: i == 2 ? _cartIconKey : null,
                              onTap: () {
                                // Повторное нажатие на текущую вкладку не
                                // даёт отклика, но по-прежнему возвращает на
                                // корневой экран из открытого поверх него.
                                if (i != currentIndex) AppMotion.selection();
                                currentTabIndex.value = i;
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Подсветка активной вкладки: фирменный градиент. Появляется с масштабом
/// 0.85 → 1 и небольшим перелётом.
class _Highlight extends StatelessWidget {
  const _Highlight({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: AppMotion.duration(context, const Duration(milliseconds: 320)),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: AppColors.softGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientEnd.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.badgeCount,
    required this.onTap,
    this.iconKey,
  });

  final List<List<dynamic>> icon;
  final String label;
  final bool active;
  final int badgeCount;
  final VoidCallback onTap;
  final GlobalKey? iconKey;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppColors.bodyText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        value: badgeCount > 0 ? '$badgeCount' : null,
        container: true,
        excludeSemantics: true,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              // Метка нужна анимации "в корзину": она берёт отсюда координаты.
              key: iconKey,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ключ по `active` перезапускает пружину при каждом выборе:
                  // иконка вырастает с 0.7 до полного размера.
                  TweenAnimationBuilder<double>(
                    key: ValueKey(active),
                    tween: Tween<double>(begin: active ? 0.7 : 1, end: 1),
                    duration: AppMotion.duration(context, const Duration(milliseconds: 380)),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: color),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, animatedColor, _) => HugeIcon(
                        icon: icon,
                        color: animatedColor ?? color,
                        size: 22,
                        // В HugeIcons нет залитых иконок — активная вкладка
                        // получает более толстую линию.
                        strokeWidth: active ? 2.0 : 1.6,
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: _Badge(count: badgeCount),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
                height: 1.3,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Бейдж появляется один раз; смена числа только перекрёстно меняет цифры.
      tween: Tween<double>(begin: 0.92, end: 1),
      duration: AppMotion.duration(context, AppMotion.fast),
      curve: AppMotion.easeOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        constraints: const BoxConstraints(minWidth: 16),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.instant),
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeOut,
          child: Text(
            count > 99 ? '99+' : '$count',
            key: ValueKey(count),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
