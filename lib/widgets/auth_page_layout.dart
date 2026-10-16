import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_theme.dart';

/// Shared presentation for sign in and sign up. The entire page scrolls when
/// the keyboard opens, including on smaller phones.
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                child: Container(
                  width: double.infinity,
                  decoration:
                      const BoxDecoration(gradient: AppColors.softGradient),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -66,
                        top: -65,
                        child: _Halo(size: 226, opacity: 0.10),
                      ),
                      Positioned(
                        left: -78,
                        bottom: -100,
                        child: _Halo(size: 188, opacity: 0.07),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(22, topInset + 12, 22, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (canPop)
                                  IconButton(
                                    tooltip: MaterialLocalizations.of(context)
                                        .backButtonTooltip,
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.15),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(44, 44),
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedArrowLeft01,
                                      color: Colors.white,
                                      size: 21,
                                    ),
                                  )
                                else
                                  const SizedBox(width: 44, height: 44),
                                const Spacer(),
                                Image.asset(
                                  'assets/branding/splash_logo.png',
                                  width: 118,
                                  height: 58,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              description,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 25, 20, 24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.isDark
                                ? const Color(0xFF382B43)
                                : const Color(0xFFF1EBF3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gradientEnd.withValues(
                                  alpha: AppColors.isDark ? 0.18 : 0.10),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
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

class _Halo extends StatelessWidget {
  const _Halo({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: opacity),
            width: 38,
          ),
        ),
      );
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.onVisibilityPressed,
    this.visibilityLabel,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final List<List<dynamic>> icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final VoidCallback? onVisibilityPressed;
  final String? visibilityLabel;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        AppColors.isDark ? const Color(0xFF493B54) : const Color(0xFFE9E2ED);
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Gilroy',
            color: AppColors.headingText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: !obscureText,
          textCapitalization: TextCapitalization.none,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            fontFamily: 'Gilroy',
            color: AppColors.headingText,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
              color: AppColors.bodyText.withValues(alpha: 0.65),
              fontFamily: 'Gilroy',
            ),
            fillColor: AppColors.scaffoldBackground,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: HugeIcon(icon: icon, color: AppColors.bodyText, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            suffixIcon: onVisibilityPressed == null
                ? null
                : IconButton(
                    tooltip: visibilityLabel,
                    onPressed: onVisibilityPressed,
                    icon: HugeIcon(
                      icon: obscureText
                          ? HugeIcons.strokeRoundedEye
                          : HugeIcons.strokeRoundedEyeOff,
                      color: AppColors.bodyText,
                      size: 20,
                    ),
                  ),
            border: outline(borderColor, 1),
            enabledBorder: outline(borderColor, 1),
            focusedBorder: outline(AppColors.accent, 1.6),
            errorBorder: outline(AppColors.danger, 1),
            focusedErrorBorder: outline(AppColors.danger, 1.6),
          ),
        ),
      ],
    );
  }
}
