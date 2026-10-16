import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Флаг языка приложения, обрезанный в круг.
class LanguageFlag extends StatelessWidget {
  const LanguageFlag({super.key, required this.code, this.size = 34});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final flag = switch (code) {
      'tk' => 'tm',
      'ru' => 'ru',
      _ => 'gb',
    };
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.bodyText.withValues(alpha: 0.35)),
      ),
      child: ClipOval(
        child: SvgPicture.asset(
          'assets/images/flags/$flag.svg',
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

class _Option {
  const _Option(this.code, this.title);
  final String code;
  final String title;
}

const _options = [
  _Option('tk', 'Türkmençe'),
  _Option('en', 'English'),
  _Option('ru', 'Русский'),
];

/// Название языка на языке интерфейса — подпись под родным названием.
const _names = {
  'ru': {'tk': 'Туркменский', 'en': 'Английский', 'ru': 'Русский'},
  'tk': {'tk': 'Türkmen dili', 'en': 'Iňlis dili', 'ru': 'Rus dili'},
  'en': {'tk': 'Turkmen', 'en': 'English', 'ru': 'Russian'},
};

/// Спрашивает язык приложения. Возвращает выбранный код или null, если
/// диалог закрыт без выбора.
Future<String?> showLanguageDialog(
  BuildContext context, {
  required String title,
  required String current,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _LanguageDialog(title: title, current: current),
    );

class _LanguageDialog extends StatelessWidget {
  const _LanguageDialog({required this.title, required this.current});

  final String title;
  final String current;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.headingText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            for (final option in _options) ...[
              _LanguageRow(
                option: option,
                subtitle: _names[current]?[option.code],
                selected: option.code == current,
                onTap: () {
                  if (option.code != current) AppMotion.selection();
                  Navigator.of(context).pop(option.code);
                },
              ),
              if (option != _options.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.option,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final _Option option;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = subtitle == null || subtitle == option.title ? null : subtitle;
    return Material(
      color: selected ? AppColors.accent.withValues(alpha: 0.10) : AppColors.subtle,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              LanguageFlag(code: option.code),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.accent : AppColors.headingText,
                      ),
                    ),
                    if (secondary != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondary,
                        style: TextStyle(fontSize: 12.5, color: AppColors.bodyText),
                      ),
                    ],
                  ],
                ),
              ),
              // Галочка, а не радио: выбор применяется сразу по нажатию.
              AnimatedScale(
                duration: AppMotion.duration(context, AppMotion.fast),
                curve: Curves.easeOutBack,
                scale: selected ? 1 : 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  child: const Center(
                    child: HugeIcon(icon: HugeIcons.strokeRoundedTick02, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
