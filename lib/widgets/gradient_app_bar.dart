import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_theme.dart';
import 'brand_shimmer.dart';

/// AppBar с фирменным градиентом сайта (#CB11AB → #481173).
/// Используется вместо обычного AppBar на всех экранах.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final double? leadingWidth;
  final double? titleSpacing;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle,
    this.leadingWidth,
    this.titleSpacing,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    final hasDrawer = scaffold?.hasDrawer ?? false;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final Widget? impliedLeading;
    if (hasDrawer) {
      impliedLeading = IconButton(
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedMenu01),
        onPressed: scaffold!.openDrawer,
      );
    } else if (canPop) {
      impliedLeading = IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
        onPressed: () => Navigator.of(context).maybePop(),
      );
    } else {
      impliedLeading = null;
    }
    return Container(
      // Без тени: панель сливается со страницей ровной линией.
      decoration: const BoxDecoration(gradient: AppColors.softGradient),
      child: AppBar(
        title: title,
        actions: actions,
        leading: leading ?? (automaticallyImplyLeading ? impliedLeading : null),
        automaticallyImplyLeading: false,
        centerTitle: centerTitle,
        leadingWidth: leadingWidth,
        titleSpacing: titleSpacing,
        bottom: bottom,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        // Material 3 добавляет тень/оттенок при прокрутке под панелью — выключено.
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

/// Картинка по URL с аккуратным состоянием загрузки/ошибки —
/// вместо стандартного [Image.network], который на Flutter Web без errorBuilder
/// показывает страшный крестик с текстом ошибки браузера.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final List<List<dynamic>> placeholderIcon;

  /// Пока фото грузится — название приложения с бликом вместо спиннера.
  final bool brandLoading;

  /// Какой частью фото прижимать при обрезке (cover). Для фото людей —
  /// bottomCenter, чтобы лица оставались в кадре.
  final Alignment alignment;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderIcon = HugeIcons.strokeRoundedImage01,
    this.brandLoading = false,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _placeholder();
    }
    if (brandLoading) {
      return Image.network(
        url!,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        // Блик лежит под фото, фото проявляется поверх, когда готово.
        frameBuilder: (context, child, frame, sync) => Stack(
          fit: StackFit.expand,
          children: [
            const BrandShimmer(),
            AnimatedOpacity(
              opacity: frame == null && !sync ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: child,
            ),
          ],
        ),
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return Image.network(
      url!,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder(loading: true);
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF5F5F5),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : HugeIcon(icon: placeholderIcon, color: Colors.grey.shade400),
    );
  }
}
