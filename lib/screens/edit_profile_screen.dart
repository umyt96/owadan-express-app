import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_field.dart';
import '../widgets/gradient_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _authService = AuthService();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  /// Значения на момент открытия: кнопка "Сохранить" активна, только когда
  /// что-то изменено.
  late final List<String> _initial;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _phone = TextEditingController(text: user?.profile?.number ?? '');
    _initial = [
      _firstName.text.trim(),
      _lastName.text.trim(),
      _email.text.trim(),
      _phone.text.trim(),
    ];
    for (final c in [_firstName, _lastName, _email, _phone]) {
      c.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _dirty {
    final now = [
      _firstName.text.trim(),
      _lastName.text.trim(),
      _email.text.trim(),
      _phone.text.trim(),
    ];
    for (var i = 0; i < now.length; i++) {
      if (now[i] != _initial[i]) return true;
    }
    return false;
  }

  bool get _emailInvalid {
    final text = _email.text.trim();
    return text.isNotEmpty && !_emailPattern.hasMatch(text);
  }

  Future<void> _save() async {
    if (_emailInvalid) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final locale = context.read<LocaleProvider>();
    try {
      final updated = await _authService.updateProfile(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        number: _phone.text.trim(),
      );
      if (!mounted) return;
      context.read<AuthProvider>().setCurrentUser(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.t('profile_updated'))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Блоки появляются по очереди — экран не "выскакивает" целиком.
  Widget _enter(int index, Widget child) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 300 + index * 70),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final fullName = '${_firstName.text} ${_lastName.text}'.trim();
    final shownName = fullName.isNotEmpty ? fullName : (user?.username ?? '');
    final initials = fullName.isEmpty
        ? ''
        : fullName
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => String.fromCharCode(w.runes.first).toUpperCase())
            .join();
    final canSave = _dirty && !_emailInvalid && !_saving;
    final noEmail = _email.text.trim().isEmpty;

    return Scaffold(
      appBar: GradientAppBar(
        title: Text(locale.t('edit_profile')),
        centerTitle: true,
      ),
      // Кнопка закреплена внизу и поднимается над клавиатурой.
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 14 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            border: Border(top: BorderSide(color: AppColors.subtle)),
          ),
          child: _SaveButton(
            label: _saving ? locale.t('saving') : locale.t('save'),
            enabled: canSave,
            busy: _saving,
            onTap: _save,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            _enter(
              0,
              Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent.withOpacity(0.25), width: 2),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: initials.isEmpty
                            ? const HugeIcon(
                                key: ValueKey('icon'),
                                icon: HugeIcons.strokeRoundedUser,
                                color: AppColors.accent,
                                size: 40,
                              )
                            : Text(
                                initials,
                                key: ValueKey(initials),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: AppColors.brand,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    shownName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: AppColors.headingText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((user?.username ?? '').isNotEmpty && fullName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${user!.username}',
                      style: TextStyle(fontFamily: 'Gilroy', color: AppColors.bodyText, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            // Без email нельзя восстановить пароль — предупреждаем прямо над полем.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: noEmail
                  ? Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const HugeIcon(
                                icon: HugeIcons.strokeRoundedInformationCircle,
                                color: AppColors.danger,
                                size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                locale.t('no_email_warning'),
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: AppColors.danger,
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 22),
            _enter(
              1,
              _FormSection(
                title: locale.t('profile_personal'),
                children: [
                  AppField(
                    controller: _firstName,
                    label: locale.t('first_name'),
                    icon: HugeIcons.strokeRoundedUser,
                    textInputAction: TextInputAction.next,
                    capitalization: TextCapitalization.words,
                  ),
                  AppField(
                    controller: _lastName,
                    label: locale.t('last_name'),
                    icon: HugeIcons.strokeRoundedUserAccount,
                    textInputAction: TextInputAction.next,
                    capitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _enter(
              2,
              _FormSection(
                title: locale.t('profile_contacts'),
                children: [
                  AppField(
                    controller: _email,
                    label: locale.t('email'),
                    icon: HugeIcons.strokeRoundedMail01,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailInvalid ? locale.t('invalid_email') : null,
                  ),
                  AppField(
                    controller: _phone,
                    label: locale.t('phone_number'),
                    icon: HugeIcons.strokeRoundedCall,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
                    onSubmitted: canSave ? _save : null,
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

/// Карточка-секция с заголовком; поля внутри разделены отступом.
class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: AppColors.bodyText,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.subtle),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientEnd.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Кнопка сохранения: активна, только когда есть изменения; при сохранении
/// заменяется индикатором.
class _SaveButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  const _SaveButton({
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled || busy;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: 54,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.subtle,
        borderRadius: BorderRadius.circular(16),
        boxShadow: active
            ? [BoxShadow(color: AppColors.accent.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 5))]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      color: enabled ? Colors.white : AppColors.bodyText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
