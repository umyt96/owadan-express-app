import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Единые длительности и кривые анимаций приложения, чтобы нижнее меню,
/// переключатели и бейджи двигались в одном ритме.
///
/// Правила: UI-анимации короче 300 мс; появление — [easeOut], перемещение
/// по экрану — [easeInOut]; нажатие никогда не уменьшает элемент меньше 0.97.
abstract final class AppMotion {
  /// Реакция на нажатие и смена цвета — укладывается в одно моргание.
  static const Duration instant = Duration(milliseconds: 120);

  /// Смена иконок, бейджи.
  static const Duration fast = Duration(milliseconds: 160);

  /// Стандарт для появления/исчезновения и скольжения.
  static const Duration standard = Duration(milliseconds: 220);

  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  static const double pressedScale = 0.97;

  /// Включён ли в системе режим "уменьшить движение".
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ??
      WidgetsBinding
          .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  /// [normal] или ноль, если система просит уменьшить движение.
  static Duration duration(BuildContext context, Duration normal) =>
      reduceMotion(context) ? Duration.zero : normal;

  /// Переход между равноправными вкладками/сегментами.
  static void selection() => HapticFeedback.selectionClick();
}
