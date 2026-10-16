import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Мягкая "пульсация" для заглушек загрузки: всё, что внутри, плавно
/// светлеет и темнеет. Фаза берётся от общих часов, поэтому несколько
/// независимых заглушек на экране пульсируют синхронно.
class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  static const _period = 1300;
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
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _ticker,
      child: widget.child,
      builder: (context, child) {
        final phase =
            (DateTime.now().millisecondsSinceEpoch % _period) / _period;
        final wave = 0.5 - 0.5 * math.cos(phase * 2 * math.pi);
        return Opacity(opacity: 0.55 + 0.45 * wave, child: child);
      },
    );
  }
}

/// Одна серая плашка заглушки.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const SkeletonBox({super.key, this.width, this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.subtle,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Заглушка плиток подкатегорий: два ряда по три, как настоящие плитки.
class SubCategoriesSkeleton extends StatelessWidget {
  const SubCategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            for (var row = 0; row < 2; row++) ...[
              if (row > 0) const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    const Expanded(child: SkeletonBox(height: 42, radius: 14)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Заглушка карточки товара (как в Elyeter): фото, цена, две строки названия
/// и кнопка на всю ширину.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Expanded(child: SkeletonBox(radius: 14)),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBox(width: 84, height: 18),
        ),
        SizedBox(height: 8),
        SkeletonBox(height: 12),
        SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
              widthFactor: 0.6, child: SkeletonBox(height: 12)),
        ),
        SizedBox(height: 14),
        SkeletonBox(height: 40, radius: 12),
      ],
    );
  }
}

/// Сетка заглушек товаров с теми же пропорциями, что и настоящая.
class ProductGridSkeleton extends StatelessWidget {
  final int count;

  const ProductGridSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.62,
        ),
        itemCount: count,
        itemBuilder: (_, __) => const ProductCardSkeleton(),
      ),
    );
  }
}

/// Заглушка заголовка раздела ("Категории — Все"): полоска и короткая метка.
class SectionHeaderSkeleton extends StatelessWidget {
  const SectionHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(16, 26, 16, 12),
        child: Row(
          children: [
            SkeletonBox(width: 4, height: 20, radius: 4),
            SizedBox(width: 10),
            SkeletonBox(width: 150, height: 20),
            Spacer(),
            SkeletonBox(width: 56, height: 16),
          ],
        ),
      );
}

/// Заглушка баннера на главной.
class BannerSkeleton extends StatelessWidget {
  const BannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonPulse(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: SkeletonBox(height: 188, radius: 14),
        ),
      );
}

/// Заглушка горизонтальной ленты с заголовком (категории, бренды).
class StripSkeleton extends StatelessWidget {
  final double height;
  final double itemWidth;
  final double radius;
  final double gap;

  const StripSkeleton({
    super.key,
    required this.height,
    required this.itemWidth,
    required this.radius,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        children: [
          const SectionHeaderSkeleton(),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              separatorBuilder: (_, __) => SizedBox(width: gap),
              itemBuilder: (_, __) =>
                  SkeletonBox(width: itemWidth, height: height, radius: radius),
            ),
          ),
        ],
      ),
    );
  }
}

/// Заглушка раздела с товарами: заголовок и сетка карточек.
class ProductSectionSkeleton extends StatelessWidget {
  final int count;

  const ProductSectionSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        children: [
          const SectionHeaderSkeleton(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              clipBehavior: Clip.none,
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              itemCount: count,
              itemBuilder: (_, __) => const ProductCardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}
