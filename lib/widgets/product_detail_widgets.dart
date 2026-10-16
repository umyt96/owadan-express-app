import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_theme.dart';
import 'gradient_app_bar.dart' show AppNetworkImage;

// Элементы страницы товара в оформлении Elyeter: белая страница, поверх неё
// мягкие плитки-секции, плавающие кнопки поверх фото и закреплённая внизу
// кнопка "в корзину".

/// Тень плавающих кнопок: на светлой теме — лёгкий подъём, на тёмной —
/// тонкая рамка (тень там не видна).
List<BoxShadow> _liftShadow(BuildContext context) =>
    AppColors.isDark
        ? const []
        : const [BoxShadow(color: Color(0x1F000000), blurRadius: 14, offset: Offset(0, 4))];

BoxBorder? _liftBorder() => AppColors.isDark ? Border.all(color: AppColors.subtle) : null;

/// Круглая кнопка "назад" над фото.
class DetailBackButton extends StatelessWidget {
  const DetailBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: _liftBorder(),
        boxShadow: _liftShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.headingText,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Два действия в одной белой "таблетке": поделиться и избранное.
class DetailActionPill extends StatelessWidget {
  final bool favorite;
  final VoidCallback onShare;
  final VoidCallback onFavorite;

  const DetailActionPill({
    super.key,
    required this.favorite,
    required this.onShare,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.headingText;
    Widget slot({required VoidCallback onTap, required Widget child}) => InkWell(
          onTap: onTap,
          child: SizedBox(width: 46, height: 44, child: Center(child: child)),
        );

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: _liftBorder(),
        boxShadow: _liftShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            slot(
              onTap: onShare,
              child: SvgPicture.asset(
                'assets/icons/share.svg',
                width: 21,
                height: 21,
                colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
              ),
            ),
            slot(
              onTap: onFavorite,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: favorite
                    ? SvgPicture.asset('assets/icons/favorite_full.svg', key: const ValueKey('on'), width: 23, height: 23)
                    : SvgPicture.asset(
                        'assets/icons/heart_line.svg',
                        key: const ValueKey('off'),
                        width: 21,
                        height: 21,
                        colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Мягкая плитка, в которую страница группирует каждый раздел. Страница
/// белая, поэтому цвет несут именно плитки.
class DetailSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DetailSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Фото товара: каждое — своя карточка, следующая выглядывает справа, так что
/// без точек понятно, что можно листать. Счётчик "1 / 6" в углу.
class DetailGallery extends StatefulWidget {
  final List<String> images;
  final void Function(int index) onOpen;
  final double height;

  const DetailGallery({
    super.key,
    required this.images,
    required this.onOpen,
    this.height = 320,
  });

  @override
  State<DetailGallery> createState() => _DetailGalleryState();
}

class _DetailGalleryState extends State<DetailGallery> {
  static const _margin = 16.0;
  final _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    if (count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _margin),
        child: SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const AppNetworkImage(url: null),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: count,
              padEnds: false,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) => Padding(
                // Последняя карточка не имеет соседа справа — ей тоже поле.
                padding: EdgeInsets.only(left: _margin, right: index == count - 1 ? _margin : 0),
                child: GestureDetector(
                  onTap: () => widget.onOpen(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ColoredBox(
                      color: AppColors.subtle,
                      child: SizedBox.expand(
                        child: AppNetworkImage(
                          url: widget.images[index],
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                          brandLoading: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (count > 1)
            Positioned(
              right: 20,
              bottom: 12,
              // Вне PageView: счётчик держит угол, пока фото плывут под ним.
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    child: Text(
                      '${_page + 1} / $count',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        color: AppColors.headingText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Зелёная оценка и сколько у товара отзывов/просмотров.
class DetailRatingRow extends StatelessWidget {
  final double? rating;
  final int reviews;
  final int views;

  const DetailRatingRow({super.key, this.rating, this.reviews = 0, this.views = 0});

  @override
  Widget build(BuildContext context) {
    final score = rating;
    Widget stat(List<List<dynamic>> icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, size: 16, color: AppColors.bodyText),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 13.5)),
          ],
        );

    return Row(
      children: [
        if (score != null) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              child: Text(
                score.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        stat(HugeIcons.strokeRoundedComment01, '$reviews'),
        const SizedBox(width: 16),
        stat(HugeIcons.strokeRoundedEye, '$views'),
      ],
    );
  }
}

/// Подпись выбранного значения под рядом вариантов: "Цвет: Красный".
class DetailOptionLabel extends StatelessWidget {
  final String text;

  const DetailOptionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 14),
      );
}

/// Ряд плашек (размеры): серая плашка, выбранная получает тёмную рамку.
class DetailChipPicker extends StatelessWidget {
  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onSelected;

  const DetailChipPicker({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          GestureDetector(
            onTap: () => onSelected(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minWidth: 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.subtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: i == selected ? AppColors.headingText : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  color: AppColors.headingText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Полоса цветов: собственные фото товара как выбираемые образцы. Тем, у кого
/// нет фото, остаётся плашка с названием.
class DetailColorPicker extends StatelessWidget {
  final List<String?> images;
  final List<String> labels;
  final int? selected;
  final ValueChanged<int> onSelected;

  const DetailColorPicker({
    super.key,
    required this.images,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  static const _size = 72.0;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = images.any((e) => e != null && e.isNotEmpty);
    if (!hasPhotos) {
      return DetailChipPicker(labels: labels, selected: selected, onSelected: onSelected);
    }
    return SizedBox(
      height: _size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = i == selected;
          final image = images[i];
          return GestureDetector(
            onTap: () => onSelected(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: _size,
              height: _size,
              // Фото занимает плитку целиком, без внутренних полей.
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.subtle,
                borderRadius: BorderRadius.circular(14),
              ),
              // Рамка рисуется поверх фото, иначе оно её закрывало бы.
              // Нейтральная: выбирают сам цвет на фото, маркер его не красит.
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? AppColors.headingText : Colors.transparent,
                  width: 2,
                ),
              ),
              child: image == null || image.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          labels[i],
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : AppNetworkImage(url: image, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

/// Крупная цена под названием: рядом — что было и сколько это экономит.
class DetailPriceRow extends StatelessWidget {
  final int? price;
  final int? oldPrice;
  final int? sale;

  const DetailPriceRow({super.key, required this.price, this.oldPrice, this.sale});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            '${price ?? '-'}',
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              color: AppColors.accent,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'TMT',
          style: TextStyle(fontFamily: 'Gilroy', color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        if (oldPrice != null) ...[
          const SizedBox(width: 12),
          Text(
            '$oldPrice',
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: AppColors.bodyText,
              fontSize: 14,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.bodyText,
            ),
          ),
          if (sale != null && sale! > 0) ...[
            const SizedBox(width: 6),
            Text(
              '-$sale%',
              style: const TextStyle(fontFamily: 'Gilroy', color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ],
    );
  }
}

/// Подпись и значение, справа кнопка "Копировать" (артикул/ID товара).
class DetailCopyCard extends StatelessWidget {
  final String label;
  final String value;
  final String copyLabel;
  final String copiedLabel;

  const DetailCopyCard({
    super.key,
    required this.label,
    required this.value,
    required this.copyLabel,
    required this.copiedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copiedLabel)));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      copyLabel,
                      style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 16, color: AppColors.headingText),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Описание, свёрнутое до пяти строк со ссылкой "Читать далее".
class DetailDescriptionCard extends StatefulWidget {
  final String title;
  final String text;
  final String moreLabel;
  final String lessLabel;

  const DetailDescriptionCard({
    super.key,
    required this.title,
    required this.text,
    required this.moreLabel,
    required this.lessLabel,
  });

  @override
  State<DetailDescriptionCard> createState() => _DetailDescriptionCardState();
}

class _DetailDescriptionCardState extends State<DetailDescriptionCard> {
  static const _collapsedLines = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 14.5, height: 1.4);

    return DetailSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // Ссылка нужна, только если текст не помещается в пять строк.
              final painter = TextPainter(
                text: TextSpan(text: widget.text, style: body),
                maxLines: _collapsedLines,
                textDirection: Directionality.of(context),
              )..layout(maxWidth: constraints.maxWidth);
              final overflows = painter.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: Text(
                      widget.text,
                      style: body,
                      maxLines: _expanded ? null : _collapsedLines,
                      overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                  if (overflows)
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _expanded ? widget.lessLabel : '${widget.moreLabel}...',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            color: AppColors.accent,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Количество: подпись слева, справа плашка с − / + и числом.
class DetailQuantityCard extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  const DetailQuantityCard({
    super.key,
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    Widget step(List<List<dynamic>> icon, VoidCallback? onTap) => InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 40,
            child: Center(
              child: HugeIcon(
                icon: icon,
                size: 18,
                color: onTap == null ? AppColors.bodyText.withOpacity(0.4) : AppColors.headingText,
              ),
            ),
          ),
        );

    return DetailSectionCard(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                step(HugeIcons.strokeRoundedMinusSign, onMinus),
                SizedBox(
                  width: 32,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Text(
                      '$value',
                      key: ValueKey(value),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                step(HugeIcons.strokeRoundedAdd01, onPlus),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Закреплённая внизу страницы кнопка — то, ради чего страница существует.
/// Нет в наличии — серая; идёт добавление — маленький индикатор; товар уже в
/// корзине — спокойная акцентная "Добавлено" с галочкой (нажатие добавит ещё).
class DetailStickyAddToCart extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool busy;
  final bool added;
  final VoidCallback onTap;

  const DetailStickyAddToCart({
    super.key,
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onTap,
    this.added = false,
  });

  static const _height = 56.0;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    final showAdded = added && enabled;
    final foreground = !enabled
        ? AppColors.bodyText
        : showAdded
            ? AppColors.accent
            : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: _height,
      decoration: BoxDecoration(
        color: !enabled
            ? AppColors.subtle
            : showAdded
                ? AppColors.accent.withOpacity(0.12)
                : AppColors.accent,
        borderRadius: BorderRadius.circular(_height / 2),
        border: Border.all(
          color: showAdded ? AppColors.accent : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: enabled && !showAdded
            ? [BoxShadow(color: AppColors.accent.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6))]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_height / 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: active ? onTap : null,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: showAdded ? AppColors.accent : Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (enabled)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutBack,
                          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                          child: showAdded
                              ? HugeIcon(
                                  key: const ValueKey('check'),
                                  icon: HugeIcons.strokeRoundedTick02,
                                  color: foreground,
                                  size: 22,
                                )
                              : SvgPicture.asset(
                                  'assets/icons/cart.svg',
                                  key: const ValueKey('cart'),
                                  width: 22,
                                  height: 22,
                                  colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                                ),
                        ),
                      if (enabled) const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
