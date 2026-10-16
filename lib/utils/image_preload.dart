import 'dart:async';

import 'package:flutter/material.dart';

import '../models/item.dart';

/// Загружает фото товаров заранее (в кэш картинок Flutter), чтобы карточки
/// появлялись уже с фото, а не с пустой заглушкой. Пока идёт загрузка, экран
/// показывает спиннер внизу списка.
///
/// Не дольше [timeout]: если какое-то фото грузится слишком долго или с
/// ошибкой, товары всё равно покажутся (фото догрузится в карточке).
Future<void> precacheItemImages(
  BuildContext context,
  Iterable<ItemSummary> items, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final futures = <Future<void>>[];
  for (final item in items) {
    final url = item.image;
    if (url == null || url.isEmpty) continue;
    // Тот же NetworkImage(url), что внутри Image.network карточки, —
    // поэтому карточка берёт фото из кэша мгновенно.
    futures.add(precacheImage(NetworkImage(url), context, onError: (_, __) {}));
  }
  if (futures.isEmpty) return;
  try {
    await Future.wait(futures).timeout(timeout);
  } catch (_) {
    // таймаут/ошибка — не мешаем показать товары
  }
}
