import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/category_link_button.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/illustrated_empty_state.dart';
import 'categories_screen.dart';

class HowToOrderScreen extends StatelessWidget {
  const HowToOrderScreen({super.key});

  static const _steps = [
    _Step(
      icon: HugeIcons.strokeRoundedSearch01,
      titleRu: 'Найдите товар',
      textRu: 'Откройте нужную категорию в каталоге или воспользуйтесь поиском.',
      titleTk: 'Harydy tapyň',
      textTk: 'Katalogdan gerekli kategoriýany saýlaň ýa-da gözlegden peýdalanyň.',
      titleEn: 'Find a product',
      textEn: 'Browse a category in the catalog or use search.',
    ),
    _Step(
      icon: HugeIcons.strokeRoundedEye,
      titleRu: 'Изучите товар',
      textRu: 'Откройте карточку товара и проверьте фотографии, описание и цену.',
      titleTk: 'Haryt bilen tanyşyň',
      textTk: 'Harydyň sahypasyny açyp, suratlaryny, beýanyny we bahasyny barlaň.',
      titleEn: 'Check the details',
      textEn: 'Open the product page and check its photos, description, and price.',
    ),
    _Step(
      icon: HugeIcons.strokeRoundedUser,
      titleRu: 'Войдите в аккаунт',
      textRu: 'Для оформления заказа войдите в свой аккаунт или зарегистрируйтесь.',
      titleTk: 'Hasabyňyza giriň',
      textTk: 'Sargyt bermek üçin hasabyňyza giriň ýa-da hasaba duruň.',
      titleEn: 'Sign in',
      textEn: 'Sign in or create an account before placing an order.',
    ),
    _Step(
      icon: HugeIcons.strokeRoundedShoppingCart01,
      titleRu: 'Добавьте товар в корзину',
      textRu: 'При необходимости выберите размер и цвет, затем добавьте товар в корзину.',
      titleTk: 'Harydy sebede goşuň',
      textTk: 'Gerek bolsa ölçegini we reňkini saýlaň, soňra harydy sebede goşuň.',
      titleEn: 'Add it to your cart',
      textEn: 'Choose a size and color if needed, then add the product to your cart.',
    ),
    _Step(
      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
      titleRu: 'Подтвердите заказ',
      textRu: 'Проверьте корзину, укажите адрес и телефон, затем подтвердите заказ.',
      titleTk: 'Sargydy tassyklaň',
      textTk: 'Sebedi barlaň, salgyny we telefon belgisini görkeziň, soňra sargydy tassyklaň.',
      titleEn: 'Confirm your order',
      textEn: 'Review your cart, enter your address and phone number, then confirm.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(title: Text(locale.t('how_to_order_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _GuideHero(locale: locale, stepCount: _steps.length),
          const SizedBox(height: 24),
          for (var index = 0; index < _steps.length; index++)
            _StepCard(
              step: _steps[index],
              number: index + 1,
              isLast: index == _steps.length - 1,
              language: locale.language,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: CategoryLinkButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
              label: locale.t('browse_categories'),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideHero extends StatelessWidget {
  const _GuideHero({required this.locale, required this.stepCount});

  final LocaleProvider locale;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
      decoration: BoxDecoration(
        gradient: AppColors.softGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientEnd.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$stepCount ${locale.t('order_guide_steps')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  locale.t('order_guide_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  locale.t('order_guide_intro'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Image.asset(
            EmptyIllustrations.catalog,
            width: 118,
            height: 132,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.number,
    required this.isLast,
    required this.language,
  });

  final _Step step;
  final int number;
  final bool isLast;
  final String language;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.softGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                elevation: 1,
                shadowColor: AppColors.gradientEnd.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: HugeIcon(
                                icon: step.icon,
                                size: 21,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step.titleFor(language),
                              style: TextStyle(
                                color: AppColors.headingText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        step.textFor(language),
                        style: TextStyle(
                          color: AppColors.bodyText,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
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

class _Step {
  const _Step({
    required this.icon,
    required this.titleRu,
    required this.textRu,
    required this.titleTk,
    required this.textTk,
    required this.titleEn,
    required this.textEn,
  });

  final List<List<dynamic>> icon;
  final String titleRu;
  final String textRu;
  final String titleTk;
  final String textTk;
  final String titleEn;
  final String textEn;

  String titleFor(String lang) => lang == 'tk'
      ? titleTk
      : lang == 'en'
          ? titleEn
          : titleRu;
  String textFor(String lang) => lang == 'tk'
      ? textTk
      : lang == 'en'
          ? textEn
          : textRu;
}
