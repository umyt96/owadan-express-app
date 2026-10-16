import 'package:flutter/material.dart';

/// Плавное появление карточки (прозрачность + небольшой сдвиг снизу) с
/// задержкой по номеру — новые товары открываются по очереди.
///
/// Каждая карточка анимируется только один раз за запуск приложения: при
/// прокрутке назад сетка пересоздаёт виджеты, но уже показанные товары
/// появляются сразу, без повторной анимации.
class AppearInTurn extends StatefulWidget {
  /// Уникальный ключ товара (id), чтобы помнить, что он уже показан.
  final Object id;

  /// Номер в списке — задержка считается по нему внутри «пачки».
  final int index;
  final Widget child;

  const AppearInTurn({super.key, required this.id, required this.index, required this.child});

  static final Set<Object> _shown = <Object>{};

  @override
  State<AppearInTurn> createState() => _AppearInTurnState();
}

class _AppearInTurnState extends State<AppearInTurn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (AppearInTurn._shown.contains(widget.id)) {
      _c.value = 1;
    } else {
      AppearInTurn._shown.add(widget.id);
      // В одной строке 2 карточки: 0,1 — сразу; 2,3 — чуть позже и т.д.
      final delay = Duration(milliseconds: 70 * (widget.index % 12));
      Future.delayed(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 18 * (1 - _curve.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
