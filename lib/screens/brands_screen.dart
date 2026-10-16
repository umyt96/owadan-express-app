import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../providers/locale_provider.dart';
import '../services/catalog_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/app_bottom_nav.dart';
import 'product_list_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/illustrated_empty_state.dart';
import '../widgets/skeleton.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  final _catalogService = CatalogService();
  late Future<List<Brand>> _future;

  @override
  void initState() {
    super.initState();
    _future = _catalogService.getBrands();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(locale.t('drawer_brands')),
        centerTitle: true,
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: FutureBuilder<List<Brand>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _BrandGridSkeleton();
          }
          final brands = snapshot.data ?? [];
          if (brands.isEmpty) {
            return IllustratedEmptyState(
              image: EmptyIllustrations.catalog,
              title: locale.t('brands_title'),
              description: locale.t('nothing_found'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              // Карточки въезжают с небольшой задержкой по порядку.
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (index % 9) * 45),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - t)),
                    child: child,
                  ),
                ),
                child: _BrandCard(
                  title: brand.title,
                  image: brand.image,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductListScreen(title: brand.title, brandId: brand.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Карточка бренда: логотип на светлой плитке (вписан целиком, без обрезки)
/// и название под ним. При нажатии слегка уменьшается.
class _BrandCard extends StatefulWidget {
  final String title;
  final String? image;
  final VoidCallback onTap;

  const _BrandCard({required this.title, required this.image, required this.onTap});

  @override
  State<_BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<_BrandCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedStore01,
        color: AppColors.accent.withOpacity(0.55),
        size: 30,
      ),
    );
    final image = widget.image;

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientEnd.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: AppColors.card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.subtle),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        // Логотипы бывают с белым фоном — плитка всегда светлая.
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.subtle),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: image == null || image.isEmpty
                          ? fallback
                          : Image.network(
                              image,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                              frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
                                opacity: frame == null && !sync ? 0 : 1,
                                duration: const Duration(milliseconds: 250),
                                child: child,
                              ),
                              errorBuilder: (_, __, ___) => fallback,
                            ),
                    ),
                  ),
                  // Название не показываем — только логотип (как на сайте).
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Заглушка загрузки: те же три колонки и пропорции, что у настоящих карточек.
class _BrandGridSkeleton extends StatelessWidget {
  const _BrandGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: 12,
        itemBuilder: (_, __) => const SkeletonBox(radius: 20),
      ),
    );
  }
}
