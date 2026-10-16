import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/contact_info.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/messages_screen.dart';
import '../services/misc_service.dart';
import '../theme/app_theme.dart';

/// Плавающие кнопки "Позвонить" / "Написать в чат" — показываются только
/// авторизованным пользователям, как на сайте (кнопка "Обратиться к
/// администратору" видна только user.is_authenticated).
///
/// ВАЖНО: сейчас подключено только на главном экране (внутри
/// MainNavigationScreen, поверх 5 вкладок). На экранах, открытых через
/// Navigator.push (детали товара, корзина, оформление заказа и т.д.), кнопки
/// не показываются, так как они перекрывают весь экран новым маршрутом. Если
/// нужно, чтобы кнопки были видны буквально на каждом экране приложения —
/// скажите, добавим их через отдельный Navigator observer.
class ContactFab extends StatefulWidget {
  const ContactFab({super.key});

  @override
  State<ContactFab> createState() => _ContactFabState();
}

class _ContactFabState extends State<ContactFab> {
  final _miscService = MiscService();
  ContactInfo? _contactInfo;

  @override
  void initState() {
    super.initState();
    _contactInfo = _miscService.cachedContactInfo;
    _miscService.getContactInfo().then((info) {
      if (mounted) setState(() => _contactInfo = info);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status != AuthStatus.authenticated) return const SizedBox.shrink();

    final locale = context.watch<LocaleProvider>();

    return Positioned(
      right: 12,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'contact_chat',
            mini: true,
            backgroundColor: AppColors.gradientEnd,
            tooltip: locale.t('chat_admin'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessagesScreen()),
            ),
            child: const HugeIcon(
                icon: HugeIcons.strokeRoundedBubbleChat, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'contact_call',
            mini: true,
            backgroundColor: AppColors.gradientEnd,
            tooltip: locale.t('call_admin'),
            onPressed: _contactInfo?.contact == null
                ? null
                : () => launchUrl(Uri.parse('tel:${_contactInfo!.contact}')),
            child: const HugeIcon(
                icon: HugeIcons.strokeRoundedCall, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
