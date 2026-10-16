import 'package:flutter/material.dart';

/// Цвета взяты напрямую из css/style.css сайта owadanexpress.com.tm,
/// а не подобраны на глаз — так интерфейс приложения совпадает с сайтом.
class AppColors {
  AppColors._();

  /// Основной фирменный градиент (шапка, кнопки заказа, бейджи, активные состояния).
  static const gradientStart = Color(0xFFCB11AB);
  static const gradientEnd = Color(0xFF481173);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Мягкий диагональный вариант того же градиента — для карточек, кнопок
  /// и акцентных блоков, где прямая горизонталь смотрится плоско.
  static const LinearGradient softGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Плоский вариант фирменного цвета — для иконок, ссылок, акцентного текста.
  static const accent = Color(0xFFCB11AB);

  /// Жёлтый — используется на сайте для hover категорий и звёзд рейтинга.
  static const gold = Color(0xFFFFD333);

  static const danger = Color(0xFFDC3545);
  static const success = Color(0xFF28A745);

  // --- Цвета, зависящие от темы (дневной / ночной режим) ---
  // Переключаются через ThemeProvider (см. applyDark), после чего всё дерево
  // виджетов перерисовывается и подхватывает новые значения.
  static bool _dark = false;
  static bool get isDark => _dark;
  static void applyDark(bool dark) => _dark = dark;

  static Color get scaffoldBackground => _dark ? const Color(0xFF15101B) : const Color(0xFFF7F5FA);
  static Color get surface => _dark ? const Color(0xFF221A2B) : const Color(0xFFFFFFFF);

  /// Фон карточек и плиток меню.
  static Color get card => surface;

  /// Приглушённый фон: заглушки картинок, "пузыри" сообщений, плитки.
  static Color get subtle => _dark ? const Color(0xFF2E2538) : const Color(0xFFEFEDF2);

  static Color get bodyText => _dark ? const Color(0xFFB8AFC4) : const Color(0xFF6C757D);
  static Color get headingText => _dark ? const Color(0xFFF1ECF6) : const Color(0xFF3D464D);

  /// Фирменный фиолетовый для текста/иконок (цены, меню). В ночном режиме
  /// светлее — тёмно-фиолетовый на тёмном фоне почти не читается.
  static Color get brand => _dark ? const Color(0xFFE38AD6) : gradientEnd;
}

class AppTheme {
  AppTheme._();

  static const double radius = 14;
  static const double smallRadius = 10;

  static ThemeData get theme => build(dark: false);
  static ThemeData get darkTheme => build(dark: true);

  /// Строит тему для нужного режима. AppColors.applyDark вызывается заранее
  /// (в ThemeProvider), поэтому геттеры AppColors уже возвращают цвета этого режима.
  static ThemeData build({required bool dark}) {
    final wasDark = AppColors.isDark;
    AppColors.applyDark(dark);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: AppColors.accent,
      secondary: AppColors.gold,
      surface: AppColors.surface,
      error: AppColors.danger,
    );

    final border = dark ? const Color(0xFF3D3249) : Colors.grey.shade300;

    final data = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      fontFamily: 'Gilroy',
      splashColor: AppColors.accent.withValues(alpha: 0.08),
      highlightColor: AppColors.accent.withValues(alpha: 0.04),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.gradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 3,
        shadowColor: AppColors.gradientEnd.withValues(alpha: 0.15),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        clipBehavior: Clip.antiAlias,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.bodyText),
        bodyMedium: TextStyle(color: AppColors.bodyText),
        titleLarge: TextStyle(color: AppColors.headingText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.headingText, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.accent.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(smallRadius)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(smallRadius)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallRadius),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallRadius),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallRadius),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shadowColor: AppColors.gradientEnd.withValues(alpha: 0.2),
        indicatorColor: AppColors.accent.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.bodyText,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.bodyText,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.accent,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(color: AppColors.headingText, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        side: BorderSide(color: border, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(color: dark ? const Color(0xFF342A3F) : Colors.grey.shade200, thickness: 1),
      drawerTheme: DrawerThemeData(backgroundColor: AppColors.surface),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: AppColors.surface),
      listTileTheme: ListTileThemeData(textColor: AppColors.headingText, iconColor: AppColors.bodyText),
    );
    // Возвращаем глобальный режим: MaterialApp строит обе темы (светлую и
    // тёмную), а активный режим задаёт ThemeProvider.
    AppColors.applyDark(wasDark);
    return data;
  }
}
