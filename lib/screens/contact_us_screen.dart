import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/contact_info.dart';
import '../providers/locale_provider.dart';
import '../services/misc_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _miscService = MiscService();
  final _formKey = GlobalKey<FormState>();
  late Future<ContactInfo> _future;

  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _miscService.getContactInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _miscService.getContactInfo(refresh: true);
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      // The contact section shows a retry action.
    }
  }

  Future<void> _send() async {
    if (_sending || _formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final locale = context.read<LocaleProvider>();
    try {
      await _miscService.sendContactMessage(
        name: _nameController.text.trim(),
        contact: _contactController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      _nameController.clear();
      _contactController.clear();
      _messageController.clear();
      _formKey.currentState?.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.t('message_sent'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openOrCopy(String value, Uri? uri) async {
    if (uri != null) {
      try {
        final opened = await launchUrl(
          uri,
          mode: uri.scheme == 'http' || uri.scheme == 'https' ? LaunchMode.externalApplication : LaunchMode.platformDefault,
        );
        if (opened) return;
      } catch (_) {
        // Keep the contact detail available through the copy fallback.
      }
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<LocaleProvider>().t('contact_copied'))),
    );
  }

  Uri? _webUri(String value) {
    final text = value.trim();
    const socialHosts = {
      'instagram.com',
      'facebook.com',
      'x.com',
      'twitter.com',
      'wa.me',
      't.me',
      'telegram.me',
      'vk.com',
    };
    var candidate = text;
    if (!text.contains('://')) {
      final host = text.split('/').first.toLowerCase().replaceFirst('www.', '');
      if (!socialHosts.contains(host)) return null;
      candidate = 'https://$text';
    }
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty) return null;
    return uri.scheme == 'http' || uri.scheme == 'https' ? uri : null;
  }

  Widget _contactDetails(ContactInfo info, LocaleProvider locale) {
    final details = <Widget>[];
    final social = <Widget>[];

    if (info.address?.trim().isNotEmpty == true) {
      final value = info.address!.trim();
      details.add(_ContactTile(
        icon: HugeIcons.strokeRoundedLocation01,
        title: locale.t('contact_address'),
        value: value,
        onTap: () => _openOrCopy(value, null),
        onLongPress: () => _openOrCopy(value, null),
        opensLink: false,
      ));
    }
    for (final value in [info.contact, info.contact2]) {
      if (value?.trim().isNotEmpty != true) continue;
      final phone = value!.trim();
      final dialable = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      details.add(_ContactTile(
        icon: HugeIcons.strokeRoundedCall,
        title: locale.t('contact_phone'),
        value: phone,
        onTap: () => _openOrCopy(
          phone,
          dialable.isEmpty ? null : Uri.parse('tel:$dialable'),
        ),
        onLongPress: () => _openOrCopy(phone, null),
        opensLink: dialable.isNotEmpty,
      ));
    }
    if (info.mail?.trim().isNotEmpty == true) {
      final email = info.mail!.trim();
      details.add(_ContactTile(
        icon: HugeIcons.strokeRoundedMail01,
        title: locale.t('email'),
        value: email,
        onTap: () => _openOrCopy(email, Uri(scheme: 'mailto', path: email)),
        onLongPress: () => _openOrCopy(email, null),
        opensLink: true,
      ));
    }

    final socialFields = <({String title, String? value, List<List<dynamic>> icon})>[
      (title: 'Instagram', value: info.instagram, icon: HugeIcons.strokeRoundedInstagram),
      (title: 'Facebook', value: info.facebook, icon: HugeIcons.strokeRoundedFacebook01),
      (title: 'X', value: info.twitter, icon: HugeIcons.strokeRoundedNewTwitter),
      (title: 'WhatsApp', value: info.whatsapp, icon: HugeIcons.strokeRoundedWhatsapp),
      (title: 'Telegram', value: info.telegram, icon: HugeIcons.strokeRoundedTelegram),
      (title: 'VK', value: info.vk, icon: HugeIcons.strokeRoundedVk),
    ];
    for (final field in socialFields) {
      if (field.value?.trim().isNotEmpty != true) continue;
      final value = field.value!.trim();
      final uri = _webUri(value);
      social.add(_ContactTile(
        icon: field.icon,
        title: field.title,
        value: value,
        onTap: () => _openOrCopy(value, uri),
        onLongPress: () => _openOrCopy(value, null),
        opensLink: uri != null,
      ));
    }

    if (details.isEmpty && social.isEmpty) {
      return _ContactStatus(
        message: locale.t('contact_info_empty'),
        retryLabel: locale.t('retry'),
        onRetry: _refresh,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.isNotEmpty) ...[
          _SectionHeading(locale.t('contact_details_title')),
          const SizedBox(height: 10),
          ...details,
        ],
        if (social.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionHeading(locale.t('contact_social_title')),
          const SizedBox(height: 10),
          ...social,
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(locale.t('contact_us')),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ContactHero(locale: locale),
                    const SizedBox(height: 24),
                    FutureBuilder<ContactInfo>(
                      future: _future,
                      initialData: _miscService.cachedContactInfo,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return _ContactStatus(
                            message: locale.t('contact_info_failed'),
                            retryLabel: locale.t('retry'),
                            onRetry: _refresh,
                          );
                        }
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        return _contactDetails(snapshot.data!, locale);
                      },
                    ),
                    const SizedBox(height: 16),
                    _ContactForm(
                      formKey: _formKey,
                      locale: locale,
                      nameController: _nameController,
                      contactController: _contactController,
                      messageController: _messageController,
                      sending: _sending,
                      onSend: _send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactHero extends StatelessWidget {
  const _ContactHero({required this.locale});

  final LocaleProvider locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.softGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedCustomerSupport,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.t('contact_hero_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  locale.t('contact_hero_body'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: AppColors.headingText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      );
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    required this.onLongPress,
    required this.opensLink,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool opensLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: HugeIcon(icon: icon, size: 22, color: AppColors.brand),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.bodyText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: TextStyle(
                          color: AppColors.headingText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                HugeIcon(
                  icon: opensLink ? HugeIcons.strokeRoundedArrowUpRight01 : HugeIcons.strokeRoundedCopy01,
                  size: 18,
                  color: AppColors.bodyText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactStatus extends StatelessWidget {
  const _ContactStatus({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            color: AppColors.brand,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.bodyText),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _ContactForm extends StatelessWidget {
  const _ContactForm({
    required this.formKey,
    required this.locale,
    required this.nameController,
    required this.contactController,
    required this.messageController,
    required this.sending,
    required this.onSend,
  });

  final GlobalKey<FormState> formKey;
  final LocaleProvider locale;
  final TextEditingController nameController;
  final TextEditingController contactController;
  final TextEditingController messageController;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    String? requiredValidator(String? value) => value == null || value.trim().isEmpty ? locale.t('contact_required') : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(locale.t('write_to_us')),
            const SizedBox(height: 5),
            Text(
              locale.t('contact_form_intro'),
              style: TextStyle(color: AppColors.bodyText, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: locale.t('your_name')),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contactController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: locale.t('phone_or_email'),
                helperText: locale.t('contact_optional'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: messageController,
              minLines: 4,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: locale.t('message')),
              validator: requiredValidator,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: sending ? null : onSend,
                iconAlignment: IconAlignment.end,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedSend,
                  size: 19,
                ),
                label: Text(locale.t(sending ? 'sending' : 'send')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
