import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/item.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../services/catalog_service.dart';
import '../services/favorite_service.dart';
import '../services/message_service.dart';
import '../theme/app_theme.dart';
import '../utils/auth_guard.dart';
import '../utils/html_utils.dart';
import '../widgets/cart_fly_animation.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/product_detail_widgets.dart';
import '../widgets/product_review_widgets.dart';
import '../widgets/app_bottom_nav.dart';
import '../services/analytics_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String slug;

  const ProductDetailScreen({super.key, required this.slug});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _catalogService = CatalogService();
  final _favoriteService = FavoriteService();
  final _messageService = MessageService();

  late Future<ItemDetail> _future;
  late Future<List<ItemSummary>> _similarFuture;

  ItemSize? _selectedSize;
  ItemColor? _selectedColor;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isAddingToCart = false;

  /// Метка кнопки внизу: из неё вылетает фото товара.
  final _addKey = GlobalKey();

  // Форма отзыва
  final _reviewController = TextEditingController();
  double _reviewRating = 5;
  bool _submittingReview = false;
  final List<XFile> _reviewImages = [];

  @override
  void initState() {
    super.initState();
    _future = _catalogService.getItem(widget.slug);
    _similarFuture = _catalogService.getSimilar(widget.slug);
    AnalyticsService.instance.screen('/product/${widget.slug}');
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _addToCart(ItemDetail item) async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    final locale = context.read<LocaleProvider>();
    if (item.sizes.isNotEmpty && _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.t('select_size_required'))),
      );
      return;
    }
    if (item.colors.isNotEmpty && _selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.t('select_color_required'))),
      );
      return;
    }
    setState(() => _isAddingToCart = true);
    final ok = await context.read<CartProvider>().addToCart(
          item.slug,
          quantity: _quantity,
          size: _selectedSize?.title,
          color: _selectedColor?.title,
        );
    if (!mounted) return;
    setState(() => _isAddingToCart = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok ? locale.t('added_to_cart') : locale.t('error'))),
    );
    // Фото летит к значку корзины в нижнем меню.
    if (ok) CartFlyAnimation.runFromKey(fromKey: _addKey, image: item.image);
  }

  Future<void> _toggleFavorite() async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    try {
      final liked = await _favoriteService.toggleFavorite(widget.slug);
      setState(() => _isFavorite = liked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${context.read<LocaleProvider>().t('error')}: $e')),
      );
    }
  }

  Future<void> _pickReviewImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() => _reviewImages.addAll(picked));
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) return;
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    final locale = context.read<LocaleProvider>();
    setState(() => _submittingReview = true);
    try {
      await _catalogService.submitReview(
        widget.slug,
        rating: _reviewRating,
        review: _reviewController.text.trim(),
        images: _reviewImages,
      );
      if (!mounted) return;
      _reviewController.clear();
      setState(() {
        _reviewImages.clear();
        _future = _catalogService
            .getItem(widget.slug); // перезагружаем с новым отзывом
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.t('review_thanks'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  // "Поделиться" — открывает системное меню шаринга (Telegram, WhatsApp,
  // Instagram и т.д.), как принято в мобильных приложениях, вместо простого
  // копирования ссылки в буфер обмена.
  Future<void> _shareProduct(ItemDetail item) async {
    final lang = context.read<LocaleProvider>().language;
    final url = 'https://owadanexpress.com.tm/product/${item.slug}/';
    await Share.share('${item.titleFor(lang)}\n$url');
  }

  void _openFullScreenGallery(
      BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _FullScreenGallery(images: images, initialIndex: initialIndex),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _askAdmin(ItemDetail item) async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    final locale = context.read<LocaleProvider>();

    final controller = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.t('contact_admin')),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                '${locale.t('question_about_product')} «${item.titleFor(locale.language)}»',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(locale.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(locale.t('send')),
          ),
        ],
      ),
    );

    if (sent != true || controller.text.trim().isEmpty) return;
    if (!mounted) return;
    try {
      await _messageService.sendMessage(controller.text.trim(),
          productId: item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.t('message_sent_to_admin'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      // Белая страница, поверх неё серые плитки — как в Elyeter.
      backgroundColor: AppColors.surface,
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: FutureBuilder<ItemDetail>(
        future: _future,
        builder: (context, snapshot) {
          final topInset = MediaQuery.paddingOf(context).top + 60;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Stack(
              children: [
                const Center(child: CircularProgressIndicator()),
                _topControls(null),
              ],
            );
          }
          if (snapshot.hasError) {
            return Stack(
              children: [
                Center(child: Text('${locale.t('error')}: ${snapshot.error}')),
                _topControls(null),
              ],
            );
          }
          final item = snapshot.data!;
          // Главное фото всегда идёт первым, затем — дополнительные (из
          // галереи "images"). Раньше, если у товара были доп. фото, главное
          // фото пропадало совсем — теперь оно всегда на первом месте.
          final galleryImages =
              item.images.map((e) => e.image).whereType<String>().toList();
          final images = <String>[
            if (item.image != null) item.image!,
            ...galleryImages.where((url) => url != item.image),
          ];

          final description = item.descriptionFor(locale.language);
          final descriptionText =
              description == null ? '' : stripHtml(description);
          final price = item.displayPriceFor(_selectedSize);
          final listPrice = item.priceFor(_selectedSize);
          final hasOldPrice = item.discountPriceFor(_selectedSize) != null &&
              listPrice != null &&
              item.discountPriceFor(_selectedSize) != listPrice;
          final selectedSizeIndex = _selectedSize == null
              ? null
              : item.sizes.indexWhere((e) => e.id == _selectedSize!.id);
          final selectedColorIndex = _selectedColor == null
              ? null
              : item.colors.indexWhere((e) => e.id == _selectedColor!.id);

          final scroll = CustomScrollView(
            slivers: [
              // Место под плавающие кнопки сверху.
              SliverToBoxAdapter(child: SizedBox(height: topInset)),
              SliverToBoxAdapter(
                child: DetailGallery(
                  images: images,
                  onOpen: (i) => _openFullScreenGallery(context, images, i),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.category != null) ...[
                        Text(
                          item.category!.titleFor(locale.language),
                          style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13.5,
                              color: AppColors.bodyText),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        item.titleFor(locale.language),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.headingText,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DetailPriceRow(
                        price: price,
                        oldPrice: hasOldPrice ? listPrice : null,
                        sale: hasOldPrice ? item.sale : null,
                      ),
                      const SizedBox(height: 12),
                      DetailRatingRow(
                        rating: item.averageRating,
                        reviews: item.reviewsCount,
                        views: item.views,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 16,
                        children: [
                          // Количество 0 — "Не доступен"; если товар есть, ничего не пишем.
                          if (item.quantity <= 0)
                            Text(
                              locale.t('out_of_stock'),
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          // Есть ли на складе прямо сейчас: Nagt bar / Nagt ýok.
                          Text(
                            item.inStock
                                ? locale.t('stock_yes')
                                : locale.t('stock_no'),
                            style: TextStyle(
                              color: item.inStock
                                  ? Colors.green.shade700
                                  : AppColors.bodyText,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                      // Артикул — сразу под ценой, чтобы его было видно без прокрутки.
                      const SizedBox(height: 14),
                      DetailCopyCard(
                        label: locale.t('article'),
                        value: '${item.id}',
                        copyLabel: locale.t('copy'),
                        copiedLabel: locale.t('copied'),
                      ),
                      if (item.sizes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        DetailChipPicker(
                          labels: [for (final size in item.sizes) size.label],
                          selected: selectedSizeIndex,
                          onSelected: (i) =>
                              setState(() => _selectedSize = item.sizes[i]),
                        ),
                        const SizedBox(height: 8),
                        DetailOptionLabel(
                            '${locale.t('size')}: ${_selectedSize?.title ?? '—'}'),
                      ],
                      if (item.colors.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        // Цвет — текстом, как размеры (без фото цвета).
                        DetailChipPicker(
                          labels: [for (final c in item.colors) c.title],
                          selected: selectedColorIndex,
                          onSelected: (i) =>
                              setState(() => _selectedColor = item.colors[i]),
                        ),
                        const SizedBox(height: 8),
                        DetailOptionLabel(
                            '${locale.t('color')}: ${_selectedColor?.title ?? '—'}'),
                      ],
                      const SizedBox(height: 22),
                      // С этого места страница — стопка серых плиток.
                      DetailQuantityCard(
                        label: locale.t('quantity'),
                        value: _quantity,
                        onMinus: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        onPlus: () => setState(() => _quantity++),
                      ),
                      if (item.delivery != null) ...[
                        const SizedBox(height: 12),
                        DetailSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  HugeIcon(
                                      icon: HugeIcons
                                          .strokeRoundedShippingTruck01,
                                      size: 20,
                                      color: AppColors.headingText),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${locale.t('delivery')}: ${item.delivery} ${locale.days(item.delivery!)}',
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        color: AppColors.headingText,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Зелёный бейдж — подчёркивает, что карго уже в цене.
                              Row(
                                children: [
                                  const HugeIcon(
                                      icon: HugeIcons
                                          .strokeRoundedCheckmarkBadge01,
                                      size: 17,
                                      color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      locale.t('cargo_included'),
                                      style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 13,
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (descriptionText.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DetailDescriptionCard(
                          title: locale.t('description'),
                          text: descriptionText,
                          moreLabel: locale.t('read_more'),
                          lessLabel: locale.t('read_less'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _askAdmin(item),
                        icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedCustomerSupport,
                            size: 18),
                        label: Text(locale.t('contact_admin')),
                      ),
                      const SizedBox(height: 24),
                      ReviewsHeader(
                        title: locale.t('reviews'),
                        count: item.reviewsCount,
                        rating: item.averageRating,
                      ),
                      const SizedBox(height: 12),
                      if (item.reviews.isEmpty)
                        ReviewEmptyCard(text: locale.t('no_reviews'))
                      else
                        for (final review in item.reviews)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ReviewCard(
                              review: review,
                              onOpenPhoto: (i) => _openFullScreenGallery(
                                  context, review.images, i),
                            ),
                          ),
                      const SizedBox(height: 4),
                      ReviewForm(
                        title: locale.t('leave_review'),
                        hint: locale.t('review_hint'),
                        addPhotosLabel: locale.t('add_photos'),
                        submitLabel: locale.t('add_review'),
                        rating: _reviewRating,
                        onRating: (v) => setState(() => _reviewRating = v),
                        controller: _reviewController,
                        images: _reviewImages,
                        onPickImages: _pickReviewImages,
                        onRemoveImage: (i) =>
                            setState(() => _reviewImages.removeAt(i)),
                        submitting: _submittingReview,
                        onSubmit: _submitReview,
                      ),
                    ],
                  ),
                ),
              ),
              // "Вам также может понравиться" — товары из той же подкатегории.
              SliverToBoxAdapter(
                child: FutureBuilder<List<ItemSummary>>(
                  future: _similarFuture,
                  builder: (context, snapshot) {
                    final similar = snapshot.data ?? [];
                    if (similar.isEmpty) return const SizedBox(height: 24);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    locale.t('you_may_also_like'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 290,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: similar.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, i) => SizedBox(
                                width: 170,
                                child: ProductCard(item: similar[i]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Место под закреплённую кнопку.
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );

          return Stack(
            children: [
              scroll,
              _topControls(item),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: DetailStickyAddToCart(
                  key: _addKey,
                  added: context.watch<CartProvider>().containsSlug(item.slug),
                  label: item.quantity < 1
                      ? locale.t('out_of_stock')
                      : (context.watch<CartProvider>().containsSlug(item.slug)
                          ? locale.t('added_to_cart')
                          : locale.t('add_to_cart')),
                  enabled: item.quantity >= 1,
                  busy: _isAddingToCart,
                  onTap: () => _addToCart(item),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Плавающие кнопки над страницей: "назад" слева, поделиться и избранное
  /// в одной таблетке справа. Пока товар грузится — только "назад".
  Widget _topControls(ItemDetail? item) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const DetailBackButton(),
              const Spacer(),
              if (item != null)
                DetailActionPill(
                  favorite: _isFavorite,
                  onShare: () => _shareProduct(item),
                  onFavorite: _toggleFavorite,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Полноэкранный просмотр фото товара — как fancybox-галерея на сайте:
/// свайп между фото, счётчик "N / всего", масштабирование щипком.
class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_index + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: AppNetworkImage(url: widget.images[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
