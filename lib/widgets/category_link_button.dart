import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_theme.dart';

class CategoryLinkButton extends StatelessWidget {
  const CategoryLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.brand,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.55), width: 1.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconAlignment: IconAlignment.end,
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 19),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
