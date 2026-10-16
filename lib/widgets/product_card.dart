import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/product_detail_screen.dart';
import '../services/favorite_service.dart';
import '../theme/app_theme.dart';
import '../utils/auth_guard.dart';
import 'brand_shimmer.dart';
import 'gradient_app_bar.dart';
import 'quick_add_to_cart_sheet.dart';

class ProductCard extends StatefulWidget {
  final ItemSummary item;

  const ProductCard({super.key, required this.item});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  static const _radius = 14.0;
  static const _surfaceRadius = 22.0;

  final _favoriteService = FavoriteService();
  late bool _isFavorite;
  bool _togglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite;
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.slug != widget.item.slug ||
        (oldWidget.item.isFavorite != widget.item.isFavorite &&
            !_togglingFavorite)) {
      _isFavorite = widget.item.isFavorite;
    }
  }

  void _favoriteLog(String color, String event, Object data) {
    if (!kDebugMode) return;
    debugPrint('\x1B[${color}m[FavoriteCard][$event] $data\x1B[0m');
  }

  Future<void> _addToCart(BuildContext context) async {
    if (!await ensureLoggedIn(context)) return;
    if (!context.mounted) return;
    // Открываем модальное окно с фото/цветом/размером — пользователь может
    // не знать заранее, какие у товара есть цвета и размеры, пока их не
    // выберет, товар в корзину не уходит (см. quick_add_to_cart_sheet.dart).
    await showQuickAddToCartSheet(context, widget.item.slug);
  }

  Future<void> _toggleFavorite() async {
    final item = widget.item;
    _favoriteLog('36', 'tap', {
      'id': item.id,
      'slug': item.slug,
      'title': item.titleFor(context.read<LocaleProvider>().language),
      'price': item.displayPrice,
      'category': item.category,
      'quantity': item.quantity,
      'isFavorite': _isFavorite,
      'targetFavorite': !_isFavorite,
    });
    if (_togglingFavorite) {
      _favoriteLog('33', 'ignored', 'request already in progress');
      return;
    }
    if (!await ensureLoggedIn(context)) {
      _favoriteLog('33', 'auth', 'login required or cancelled');
      return;
    }
    if (!mounted) return;
    final wasFavorite = _isFavorite;
    setState(() {
      _togglingFavorite = true;
      _isFavorite = !wasFavorite; // оптимистичное переключение
    });
    try {
      final liked = await _favoriteService.toggleFavorite(item.slug);
      _favoriteLog('32', 'success', {'slug': item.slug, 'liked': liked});
      if (mounted) setState(() => _isFavorite = liked);
    } catch (error) {
      _favoriteLog('31', 'error', {'slug': item.slug, 'error': error});
      if (mounted) {
        setState(() => _isFavorite = wasFavorite); // откат при ошибке
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${context.read<LocaleProvider>().t('error')}: $error'),
        ));
      }
    } finally {
      if (mounted) setState(() => _togglingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final item = widget.item;

    final inStock = item.quantity >= 1;
    // Товар уже в корзине — кнопка говорит об этом, а не зовёт добавить.
    final inCart =
        context.select<CartProvider, bool>((c) => c.containsSlug(item.slug));
    final hasOldPrice = item.discountPrice != null &&
        item.price != null &&
        item.discountPrice != item.price;

    // Карточка как в Elyeter: без рамки и подложки — квадратное фото со
    // скруглением, под ним цена, название и кнопка на всю ширину.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(slug: item.slug)),
        );
      },
      // Белая подложка за всей карточкой; фото и подписи лежат на ней с полем.
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(_surfaceRadius),
          border: Border.all(color: AppColors.subtle),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientEnd.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  // Без тени вокруг фото: на белой подложке она читалась как
                  // серое поле вокруг картинки.
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_radius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_radius),
                    child: ColoredBox(
                      color: AppColors.subtle,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          item.image != null
                              ? AppNetworkImage(
                                  url: item.image,
                                  fit: BoxFit.cover,
                                  // Лица на фото обычно в нижней части кадра.
                                  alignment: Alignment.bottomCenter,
                                  brandLoading: true)
                              : const BrandShimmer(),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: _FavoriteButton(
                                active: _isFavorite, onTap: _toggleFavorite),
                          ),
                          if (item.sale != null && item.sale! > 0)
                            Positioned(
                              left: 2,
                              bottom: 2,
                              child: IgnorePointer(
                                  child: _DiscountTicket(percent: item.sale!)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      '${item.displayPrice ?? '-'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        color: AppColors.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'TMT',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasOldPrice) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${item.price}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.bodyText,
                          color: AppColors.bodyText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Место под ДВЕ строки заложено всегда: от длины названия высота
              // блока не меняется, поэтому фото у всех карточек одного размера.
              SizedBox(
                height: 34,
                child: Text(
                  item.titleFor(locale.language),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: AppColors.bodyText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _AddToCartButton(
                label: !inStock
                    ? locale.t('out_of_stock')
                    : (inCart
                        ? locale.t('added_to_cart')
                        : locale.t('add_to_cart')),
                enabled: inStock,
                added: inStock && inCart,
                onTap: () => _addToCart(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Сердечко "Избранное" поверх фото: белый кружок, при включении — красное
/// заполненное сердце, появляющееся с пружиной.
class _FavoriteButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FavoriteButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      elevation: 1.5,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: active
                  ? SvgPicture.asset('assets/icons/favorite_full.svg',
                      key: const ValueKey('on'), width: 22, height: 22)
                  : SvgPicture.asset(
                      'assets/icons/heart_line.svg',
                      key: const ValueKey('off'),
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                          Color(0xFF3D464D), BlendMode.srcIn),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `-20%` — зелёный билетик слева внизу фото: готовая иллюстрация с процентом
/// поверх.
class _DiscountTicket extends StatelessWidget {
  final int percent;

  const _DiscountTicket({required this.percent});

  static const _width = 56.0;
  static const _height = 32.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset('assets/icons/discount_banner.svg',
              width: _width, height: _height),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: FittedBox(
              child: Text(
                '-$percent%',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Серая кнопка на всю ширину: значок корзины у левого края, подпись по
/// центру. Нет в наличии — приглушена и неактивна.
class _AddToCartButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool added;
  final VoidCallback onTap;

  const _AddToCartButton({
    required this.label,
    required this.enabled,
    required this.added,
    required this.onTap,
  });

  static const _height = 40.0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final color = added
        ? Colors.white
        : (enabled ? AppColors.headingText : AppColors.bodyText);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: _height,
        decoration: BoxDecoration(
          color: added ? AppColors.accent : AppColors.subtle,
          borderRadius: radius,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: radius,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 12,
                  // Значок меняется на галочку с лёгким "пружинным" появлением.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: added
                        ? const HugeIcon(
                            key: ValueKey('check'),
                            icon: HugeIcons.strokeRoundedTick02,
                            color: Colors.white,
                            size: 20,
                          )
                        : SvgPicture.asset(
                            'assets/icons/cart.svg',
                            key: const ValueKey('cart'),
                            width: 20,
                            height: 20,
                            colorFilter:
                                ColorFilter.mode(color, BlendMode.srcIn),
                          ),
                  ),
                ),
                // Вне значка с обеих сторон, чтобы подпись оставалась по центру;
                // если не помещается — уменьшается, а не обрезается.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
