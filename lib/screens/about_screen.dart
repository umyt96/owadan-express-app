import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../models/about_page.dart';
import '../providers/locale_provider.dart';
import '../services/misc_service.dart';
import '../theme/app_theme.dart';
import '../utils/html_utils.dart';
import '../widgets/gradient_app_bar.dart';
import 'contact_us_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _miscService = MiscService();
  late Future<List<AboutPage>> _future;

  @override
  void initState() {
    super.initState();
    _future = _miscService.getAbout();
  }

  Future<void> _reload() async {
    final future = _miscService.getAbout();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder shows the error and retry action.
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(locale.t('about_us')),
        centerTitle: true,
      ),
      body: FutureBuilder<List<AboutPage>>(
        future: _future,
        builder: (context, snapshot) {
          final pages = snapshot.data?.where((page) => page.titleFor(locale.language).trim().isNotEmpty || stripHtml(page.textFor(locale.language)).isNotEmpty).toList() ?? [];

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                _AboutHero(locale: locale),
                const SizedBox(height: 20),
                if (snapshot.connectionState == ConnectionState.waiting)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(locale.t('loading')),
                      ],
                    ),
                  )
                else if (snapshot.hasError || pages.isEmpty)
                  _AboutStatus(
                    message: locale.t(snapshot.hasError ? 'about_load_failed' : 'about_empty'),
                    retryLabel: locale.t('retry'),
                    onRetry: _reload,
                  )
                else ...[
                  for (final page in pages) ...[
                    _AboutContentCard(page: page, locale: locale),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 6),
                  _ContactCard(
                    locale: locale,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ContactUsScreen(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero({required this.locale});

  final LocaleProvider locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.softGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientEnd.withValues(alpha: 0.17),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -58,
              right: -46,
              child: Container(
                width: 178,
                height: 178,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 28,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/branding/splash_logo.png',
                    width: 170,
                    height: 104,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    semanticLabel: locale.t('app_name'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    locale.t('about_hero_subtitle'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutContentCard extends StatelessWidget {
  const _AboutContentCard({required this.page, required this.locale});

  final AboutPage page;
  final LocaleProvider locale;

  @override
  Widget build(BuildContext context) {
    final title = page.titleFor(locale.language).trim();
    final paragraphs = stripHtml(page.textFor(locale.language)).split(RegExp(r'\n+')).map((paragraph) => paragraph.trim()).where((paragraph) => paragraph.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientEnd.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  size: 22,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.isEmpty ? locale.t('about_us') : title,
                  style: TextStyle(
                    color: AppColors.headingText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          if (paragraphs.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (var index = 0; index < paragraphs.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              SelectableText(
                paragraphs[index],
                style: TextStyle(
                  color: AppColors.bodyText,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.locale, required this.onTap});

  final LocaleProvider locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCustomerSupport,
                  size: 24,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.t('contact_us'),
                      style: TextStyle(
                        color: AppColors.headingText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locale.t('about_contact_prompt'),
                      style: TextStyle(
                        color: AppColors.bodyText,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 20,
                color: AppColors.brand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutStatus extends StatelessWidget {
  const _AboutStatus({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            color: AppColors.brand,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.bodyText, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh01,
              size: 18,
            ),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
