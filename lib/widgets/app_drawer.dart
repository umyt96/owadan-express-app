import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/brands_screen.dart';
import '../screens/product_list_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_reveal.dart';
import 'language_dialog.dart';

/// Боковое меню: Главная, Все, Скидки, Бренды и настройки (язык, тема).
/// Разделы собраны в карточки, как в профиле. "О нас", контакты и политика
/// конфиденциальности — в профиле.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final theme = context.watch<ThemeProvider>();

    void go(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    void push(Widget screen) => go(() => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen)));

    Future<void> pickLanguage() async {
      final picked = await showLanguageDialog(
        context,
        title: locale.t('language'),
        current: locale.language,
      );
      if (picked != null) await locale.setLanguage(picked);
    }

    void setDark(bool on) {
      if (theme.isDark == on) return;
      void change() => theme.setMode(on ? ThemeMode.dark : ThemeMode.light);
      final reveal = ThemeReveal.maybeOf(context);
      if (reveal == null) {
        change();
      } else {
        unawaited(reveal.run(
          change,
          direction: on
              ? ThemeRevealDirection.leftToRight
              : ThemeRevealDirection.rightToLeft,
        ));
      }
    }

    // Строки появляются по очереди — меню не "выскакивает" целиком.
    Widget enter(int index, Widget child) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 260 + index * 50),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(-14 * (1 - t), 0),
              child: child,
            ),
          ),
          child: child,
        );

    return Drawer(
      backgroundColor: AppColors.scaffoldBackground,
      width: 304,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _DrawerHeader(tagline: locale.t('home_tagline')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
              children: [
                enter(
                  0,
                  _DrawerGroup(
                    title: locale.t('drawer_section_catalog'),
                    children: [
                      _DrawerItem(
                        icon: HugeIcons.strokeRoundedHome01,
                        label: locale.t('drawer_home'),
                        onTap: () => go(() => Navigator.of(context)
                            .popUntil((route) => route.isFirst)),
                      ),
                      _DrawerItem(
                        icon: HugeIcons.strokeRoundedGridView,
                        label: locale.t('drawer_all'),
                        onTap: () => push(
                            ProductListScreen(title: locale.t('drawer_all'))),
                      ),
                      _DrawerItem(
                        icon: HugeIcons.strokeRoundedSaleTag01,
                        label: locale.t('drawer_sale'),
                        onTap: () => push(ProductListScreen(
                          title: locale.t('drawer_sale'),
                          onlyDiscounted: true,
                        )),
                      ),
                      _DrawerItem(
                        icon: HugeIcons.strokeRoundedPackageDelivered,
                        label: locale.t('drawer_in_stock'),
                        onTap: () => push(ProductListScreen(
                          title: locale.t('drawer_in_stock'),
                          onlyInStock: true,
                        )),
                      ),
                      _DrawerItem(
                        icon: HugeIcons.strokeRoundedStore01,
                        label: locale.t('drawer_brands'),
                        onTap: () => push(const BrandsScreen()),
                      ),
                    ],
                  ),
                ),
                enter(
                  1,
                  _DrawerGroup(
                    title: locale.t('section_preferences'),
                    children: [
                      // Язык и тема меняются, не закрывая меню.
                      _DrawerItem(
                        icon: HugeIcons.strokeRoundedLanguageCircle,
                        label: locale.t('language'),
                        trailing: LanguageFlag(code: locale.language, size: 30),
                        onTap: pickLanguage,
                      ),
                      _DrawerItem(
                        icon: theme.isDark
                            ? HugeIcons.strokeRoundedMoon02
                            : HugeIcons.strokeRoundedSun01,
                        label: locale.t('dark_mode'),
                        trailing: CupertinoSwitch(
                          value: theme.isDark,
                          activeTrackColor: AppColors.accent,
                          onChanged: setDark,
                        ),
                        onTap: () => setDark(!theme.isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Шапка меню: сплошной фирменный цвет, логотип и подпись; полупрозрачные
/// круги в углах дают глубину без картинок.
class _DrawerHeader extends StatelessWidget {
  final String tagline;

  const _DrawerHeader({required this.tagline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.gradientEnd,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -34,
            child: _Circle(size: 140, opacity: 0.09),
          ),
          Positioned(
            bottom: -54,
            left: -30,
            child: _Circle(size: 120, opacity: 0.06),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    'https://owadanexpress.com.tm/static/img/white_logo.png',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'Owadan Express',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tagline,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;

  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity),
          ),
        ),
      );
}

/// Карточка-раздел: заголовок и строки через тонкую линию.
class _DrawerGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DrawerGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 62,
          endIndent: 14,
          color: AppColors.subtle,
        ));
      }
      rows.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: AppColors.bodyText,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Material(
            color: AppColors.card,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.subtle),
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(icon: icon, color: AppColors.brand, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  color: AppColors.headingText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing ??
                HugeIcon(
                  icon: HugeIcons.strokeRoundedChevronRight,
                  color: AppColors.bodyText.withOpacity(0.7),
                  size: 18,
                ),
          ],
        ),
      ),
    );
  }
}
