import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/brand_primary_button.dart';
import 'register_screen.dart';
import '../services/analytics_service.dart';

/// Возвращает true через Navigator.pop, если пользователь успешно вошёл
/// (или зарегистрировался) — так экран, который открыл LoginScreen ради
/// защищённого действия, может продолжить это действие.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  // Кнопка Apple — только если вход через Apple настроен на сервере.
  bool _appleEnabled = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().isAppleEnabled().then((v) {
      if (mounted && v) setState(() => _appleEnabled = true);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      AnalyticsService.instance.event('login', data: {'method': 'password'});
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(auth.errorMessage ??
                context.read<LocaleProvider>().t('login_failed'))),
      );
    }
  }

  Future<void> _submitGoogle() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();
    if (!mounted) return;
    if (success) {
      AnalyticsService.instance.event('login', data: {'method': 'google'});
      Navigator.of(context).pop(true);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
    // Если success == false и errorMessage == null — пользователь просто
    // отменил выбор Google-аккаунта, ничего показывать не нужно.
  }

  Future<void> _submitYandex() =>
      _submitVia('yandex', context.read<AuthProvider>().loginWithYandex);

  Future<void> _submitApple() =>
      _submitVia('apple', context.read<AuthProvider>().loginWithApple);

  Future<void> _submitVia(String method, Future<bool> Function() login) async {
    final auth = context.read<AuthProvider>();
    final success = await login();
    if (!mounted) return;
    if (success) {
      AnalyticsService.instance.event('login', data: {'method': method});
      Navigator.of(context).pop(true);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  /// "Забыли пароль?": вводим email — сервер отправляет на почту ссылку,
  /// по которой задаётся новый пароль (как на сайте).
  Future<void> _forgotPassword() async {
    final locale = context.read<LocaleProvider>();
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.t('forgot_password')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.t('reset_password_hint')),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: locale.t('email')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(locale.t('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(locale.t('send')),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    if (!email.contains('@')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(locale.t('invalid_email'))));
      return;
    }
    try {
      await AuthService().requestPasswordReset(email);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon:
              const HugeIcon(icon: HugeIcons.strokeRoundedMailCheck, size: 40),
          title: Text(locale.t('check_email')),
          content: Text('${locale.t('reset_email_sent')} $email'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(locale.t('ok'))),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _goToRegister() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    final googleStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      foregroundColor: const Color(0xFF1F1F1F),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFDADCE0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle:
          const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700),
    );
    final yandexStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      foregroundColor: AppColors.headingText,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: AppColors.isDark
            ? const Color(0xFF493B54)
            : const Color(0xFFE9E2ED),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle:
          const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700),
    );

    return AuthPageLayout(
      title: locale.t('login_title'),
      description: locale.t('login_intro'),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _usernameController,
                label: locale.t('username'),
                icon: HugeIcons.strokeRoundedUser,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? locale.t('required_field')
                    : null,
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _passwordController,
                label: locale.t('password'),
                icon: HugeIcons.strokeRoundedLockPassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                obscureText: !_passwordVisible,
                onVisibilityPressed: () => setState(
                  () => _passwordVisible = !_passwordVisible,
                ),
                visibilityLabel: locale.t(
                  _passwordVisible ? 'hide_password' : 'show_password',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? locale.t('required_field')
                    : null,
                onFieldSubmitted: (_) {
                  if (!auth.isLoading) _submit();
                },
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: auth.isLoading ? null : _forgotPassword,
                  child: Text(locale.t('forgot_password')),
                ),
              ),
              const SizedBox(height: 12),
              if (auth.isLoading)
                const SizedBox(
                  height: 54,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                BrandPrimaryButton(
                  onPressed: _submit,
                  label: locale.t('login_button'),
                ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      locale.t('login_with'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 17),
              OutlinedButton.icon(
                style: googleStyle,
                onPressed: auth.isLoading ? null : _submitGoogle,
                icon: Image.asset(
                  'assets/branding/google_g.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                label: Text(locale.t('login_google')),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: yandexStyle,
                onPressed: auth.isLoading ? null : _submitYandex,
                icon: ClipOval(
                  child: Image.asset(
                    locale.language == 'ru'
                        ? 'assets/branding/yandex_ru.png'
                        : 'assets/branding/yandex_en.png',
                    width: 23,
                    height: 23,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                label: Text(locale.t('login_yandex')),
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: auth.isLoading ? 0.55 : 1,
                child: Material(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: auth.isLoading
                        ? null
                        : _appleEnabled
                            ? _submitApple
                            : () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(locale.t('apple_soon')),
                                  ),
                                ),
                    child: SizedBox(
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 0,
                            child: Image.asset(
                              'assets/branding/apple_sign_in_logo.png',
                              width: 52,
                              height: 52,
                              excludeFromSemantics: true,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 56),
                            child: Text(
                              locale.t('login_apple'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    locale.t('auth_no_account'),
                    style: TextStyle(color: AppColors.bodyText, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: auth.isLoading ? null : _goToRegister,
                    child: Text(locale.t('register_title')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
