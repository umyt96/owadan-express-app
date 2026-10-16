import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/locale_provider.dart';
import '../widgets/gradient_app_bar.dart';

/// Политика конфиденциальности хранится на сайте (core:politic) как HTML-
/// страница с текстом на русском/туркменском через modeltranslation — проще
/// и надёжнее открыть её во встроенном браузере, чем дублировать текст и
/// парсинг HTML в приложении.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _url = 'https://owadanexpress.com.tm/politic/';

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(title: Text(locale.t('drawer_privacy'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                  icon: HugeIcons.strokeRoundedShield01,
                  size: 56,
                  color: Colors.grey),
              const SizedBox(height: 16),
              Text(locale.t('privacy_open_hint'), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse(_url),
                    mode: LaunchMode.externalApplication),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedExternalLink),
                label: Text(locale.t('drawer_privacy')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
