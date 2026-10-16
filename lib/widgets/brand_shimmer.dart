import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Заглушка загрузки фото: название приложения, по которому пробегает блик.
/// Фаза блика берётся от общих часов — все карточки на экране переливаются
/// синхронно, а не каждая в своём ритме.
class BrandShimmer extends StatefulWidget {
  const BrandShimmer({super.key});

  @override
  State<BrandShimmer> createState() => _BrandShimmerState();
}

class _BrandShimmerState extends State<BrandShimmer>
    with SingleTickerProviderStateMixin {
  static const _period = 1500;
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _period),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.bodyText.withOpacity(0.28);
    final highlight = AppColors.accent.withOpacity(0.95);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget label(Color color) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Owadan',
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                height: 1.05,
              ),
            ),
            Text(
              'EXPRESS',
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 4,
                height: 1.2,
              ),
            ),
          ],
        );

    return ColoredBox(
      color: AppColors.subtle,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: reduceMotion
                ? label(base)
                : AnimatedBuilder(
                    animation: _ticker,
                    builder: (context, _) {
                      final t =
                          (DateTime.now().millisecondsSinceEpoch % _period) /
                              _period;
                      return ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [base, highlight, base],
                          stops: const [0.35, 0.5, 0.65],
                          // Блик едет слева направо за пределы текста.
                          begin: Alignment(-2.0 + 4.0 * t, -0.3),
                          end: Alignment(-1.0 + 4.0 * t, 0.3),
                        ).createShader(bounds),
                        child: label(Colors.white),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
