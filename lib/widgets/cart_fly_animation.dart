import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_theme.dart';

/// Анимация "товар летит в корзину": миниатюра фото вылетает из нажатой кнопки
/// и по дуге опускается на значок корзины в нижнем меню.
///
/// Это только картинка — само добавление делает вызывающий код.
///
/// Нижнее меню в приложении есть и на главной, и на открытых поверх неё
/// экранах, поэтому ключей сразу несколько. Каждое меню регистрирует свой
/// ([register]) и снимает при закрытии ([unregister]); летим к тому, что
/// зарегистрировано последним, то есть к видимому.
abstract final class CartFlyAnimation {
  static final List<GlobalKey> _targets = [];

  static void register(GlobalKey key) => _targets.add(key);

  static void unregister(GlobalKey key) => _targets.remove(key);

  /// Летит из центра виджета с ключом [fromKey] (обычно — нажатая кнопка).
  static void runFromKey({required GlobalKey fromKey, String? image}) {
    final context = fromKey.currentContext;
    if (context == null) return;
    runFrom(fromContext: context, image: image);
  }

  /// Летит из центра [fromContext].
  static void runFrom({required BuildContext fromContext, String? image}) {
    final box = fromContext.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    run(
      context: fromContext,
      startCenter: box.localToGlobal(box.size.center(Offset.zero)),
      image: image,
    );
  }

  static void run({required BuildContext context, required Offset startCenter, String? image}) {
    if (MediaQuery.disableAnimationsOf(context)) return;

    // Последнее зарегистрированное меню, которое сейчас на экране.
    RenderBox? target;
    for (final key in _targets.reversed) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.attached && box.hasSize) {
        target = box;
        break;
      }
    }
    if (target == null) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlyingItem(
        start: startCenter,
        end: target!.localToGlobal(target.size.center(Offset.zero)),
        onCompleted: entry.remove,
        child: _FlyingThumb(image: image == null || image.isEmpty ? null : NetworkImage(image)),
      ),
    );
    overlay.insert(entry);
  }
}

/// То, что летит: фото товара в круге с акцентной рамкой.
class _FlyingThumb extends StatelessWidget {
  const _FlyingThumb({this.image});

  static const size = 46.0;

  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: AppColors.accent, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
        image: image == null ? null : DecorationImage(image: image!, fit: BoxFit.cover, alignment: Alignment.bottomCenter),
      ),
      child: image == null
          ? const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedShoppingBag01, color: AppColors.accent, size: 20))
          : null,
    );
  }
}

class _FlyingItem extends StatefulWidget {
  const _FlyingItem({
    required this.start,
    required this.end,
    required this.child,
    required this.onCompleted,
  });

  final Offset start;
  final Offset end;
  final Widget child;
  final VoidCallback onCompleted;

  @override
  State<_FlyingItem> createState() => _FlyingItemState();
}

class _FlyingItemState extends State<_FlyingItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  /// На сколько полёт выгибается над прямой линией в середине пути.
  static const _arcHeight = 130.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInCubic);
    _controller.forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        final dx = ui.lerpDouble(widget.start.dx, widget.end.dx, t)!;
        // Парабола: полёт идёт дугой вверх, а не напрямую вниз к вкладке.
        final dy = ui.lerpDouble(widget.start.dy, widget.end.dy, t)! - _arcHeight * t * (1 - t);
        final scale = ui.lerpDouble(1, 0.25, t)!;
        final opacity = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);

        return Positioned(
          left: dx - _FlyingThumb.size / 2,
          top: dy - _FlyingThumb.size / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
