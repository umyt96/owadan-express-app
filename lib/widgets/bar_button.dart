import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_theme.dart';

/// Круглая "стеклянная" кнопка верхней панели: полупрозрачная плитка с тонкой
/// рамкой. При нажатии слегка уменьшается; бейдж появляется с пружиной.
class BarButton extends StatefulWidget {
  const BarButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badgeCount = 0,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final String tooltip;
  final int badgeCount;

  @override
  State<BarButton> createState() => BarButtonState();
}

class BarButtonState extends State<BarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white.withOpacity(0.16),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withOpacity(0.24)),
              ),
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    // Смена иконки (лупа ↔ крестик) — поворот с проявлением.
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) =>
                          RotationTransition(
                        turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: HugeIcon(
                        key: ValueKey(widget.icon),
                        icon: widget.icon,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.badgeCount > 0)
              Positioned(
                top: -5,
                right: -5,
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(widget.badgeCount),
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          widget.badgeCount > 99
                              ? '99+'
                              : '${widget.badgeCount}',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
