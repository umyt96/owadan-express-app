import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_theme.dart';

/// Поле ввода: слева плитка с иконкой (подсвечивается при фокусе), заливка
/// без рамки, при ошибке — красная рамка и подпись.
class AppField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final List<List<dynamic>> icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? formatters;
  final String? errorText;
  final VoidCallback? onSubmitted;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.capitalization = TextCapitalization.none,
    this.formatters,
    this.errorText,
    this.onSubmitted,
  });

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final focused = _focus.hasFocus;
    final tint = hasError ? AppColors.danger : (focused ? AppColors.accent : AppColors.bodyText);

    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.capitalization,
      inputFormatters: widget.formatters,
      cursorColor: AppColors.accent,
      onSubmitted: (_) => widget.onSubmitted?.call(),
      style: TextStyle(
        fontFamily: 'Gilroy',
        color: AppColors.headingText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        labelStyle: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 15),
        floatingLabelStyle: TextStyle(fontFamily: 'Gilroy', color: tint, fontWeight: FontWeight.w700),
        errorStyle: const TextStyle(fontFamily: 'Gilroy', color: AppColors.danger, fontSize: 12.5),
        filled: true,
        fillColor: AppColors.subtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(child: HugeIcon(icon: widget.icon, color: tint, size: 19)),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
    );
  }
}
