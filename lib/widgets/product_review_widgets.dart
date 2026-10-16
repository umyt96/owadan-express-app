import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../models/item.dart';
import '../theme/app_theme.dart';
import 'gradient_app_bar.dart' show AppNetworkImage;

// Блок "Отзывы" на странице товара: сводка оценки, карточки отзывов и форма
// нового отзыва — в том же оформлении, что и остальные плитки страницы.

const _starColor = Color(0xFFFFB400);

/// Ряд из пяти звёзд: целиком заполненные до [value], остальные бледные.
class _Stars extends StatelessWidget {
  final double value;
  final double size;

  const _Stars({required this.value, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            Icons.star_rounded,
            size: size,
            color: i <= value.round() ? _starColor : AppColors.bodyText.withOpacity(0.25),
          ),
      ],
    );
  }
}

/// Заголовок раздела со счётчиком и крупной сводкой оценки.
class ReviewsHeader extends StatelessWidget {
  final String title;
  final int count;
  final double? rating;

  const ReviewsHeader({super.key, required this.title, required this.count, this.rating});

  @override
  Widget build(BuildContext context) {
    final score = rating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontFamily: 'Gilroy', color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        if (score != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.subtle, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 40, fontWeight: FontWeight.w800, height: 1),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Stars(value: score, size: 22),
                    const SizedBox(height: 4),
                    Text('$count', style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 13.5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Когда отзывов ещё нет.
class ReviewEmptyCard extends StatelessWidget {
  final String text;

  const ReviewEmptyCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(color: AppColors.subtle, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedComment01, size: 30, color: AppColors.bodyText.withOpacity(0.6)),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Один отзыв: кружок с инициалом, имя и дата, звёзды, текст и фото.
class ReviewCard extends StatelessWidget {
  final Review review;
  final void Function(int index) onOpenPhoto;

  const ReviewCard({super.key, required this.review, required this.onOpenPhoto});

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final name = review.user.trim();
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();
    final date = review.createdDate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.subtle, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.14), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(fontFamily: 'Gilroy', color: AppColors.brand, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? '—' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    if (date != null)
                      Text(_date(date), style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 12.5)),
                  ],
                ),
              ),
              _Stars(value: review.rating, size: 17),
            ],
          ),
          if (review.review.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.review,
              style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 14.5, height: 1.4),
            ),
          ],
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => onOpenPhoto(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: AppNetworkImage(url: review.images[i], fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Форма нового отзыва: крупные звёзды, поле текста, фото и отправка.
class ReviewForm extends StatelessWidget {
  final String title;
  final String hint;
  final String addPhotosLabel;
  final String submitLabel;
  final double rating;
  final ValueChanged<double> onRating;
  final TextEditingController controller;
  final List<XFile> images;
  final VoidCallback onPickImages;
  final void Function(int index) onRemoveImage;
  final bool submitting;
  final VoidCallback onSubmit;

  const ReviewForm({
    super.key,
    required this.title,
    required this.hint,
    required this.addPhotosLabel,
    required this.submitLabel,
    required this.rating,
    required this.onRating,
    required this.controller,
    required this.images,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.subtle, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onRating(i.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AnimatedScale(
                      // Выбранная оценка чуть "подпрыгивает".
                      scale: i == rating.round() ? 1.15 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        Icons.star_rounded,
                        size: 36,
                        color: i <= rating ? _starColor : AppColors.bodyText.withOpacity(0.25),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 3,
            cursorColor: AppColors.accent,
            style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 15),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
              ),
            ),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: FutureBuilder<Uint8List>(
                        future: images[i].readAsBytes(),
                        builder: (context, snapshot) => SizedBox(
                          width: 72,
                          height: 72,
                          child: snapshot.hasData
                              ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                              : ColoredBox(color: AppColors.surface),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemoveImage(i),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black54,
                          child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPickImages,
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, size: 20, color: AppColors.headingText),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              addPhotosLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: 'Gilroy', color: AppColors.headingText, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: submitting ? null : onSubmit,
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : Text(
                                submitLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: 'Gilroy', color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
