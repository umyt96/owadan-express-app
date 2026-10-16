import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_primary_button.dart';
import 'category_link_button.dart';

class EmptyIllustrations {
  static const cart = 'assets/illustrations/empty_cart.png';
  static const favorites = 'assets/illustrations/empty_favorites.png';
  static const catalog = 'assets/illustrations/empty_catalog.png';
  static const orders = 'assets/illustrations/empty_orders.png';
  static const guest = 'assets/illustrations/guest_profile.png';
}

/// Scrollable even when empty, so pull-to-refresh remains available.
class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.image,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.actionButton,
    this.transparentAction = false,
  });

  final String image;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? actionButton;
  final bool transparentAction;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 236,
                    height: 236,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.055),
                    ),
                    child: Image.asset(image,
                        fit: BoxFit.contain, excludeFromSemantics: true),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.headingText,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.bodyText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (actionButton != null ||
                      (actionLabel != null && onAction != null)) ...[
                    const SizedBox(height: 24),
                    if (actionButton != null)
                      actionButton!
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: SizedBox(
                          width: double.infinity,
                          child: transparentAction
                              ? CategoryLinkButton(
                                  label: actionLabel!,
                                  onPressed: onAction!,
                                )
                              : BrandPrimaryButton(
                                  label: actionLabel!,
                                  onPressed: onAction!,
                                ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
