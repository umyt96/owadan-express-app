import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/brand_primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _phone = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      number: _phone.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(auth.errorMessage ??
                context.read<LocaleProvider>().t('registration_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    return AuthPageLayout(
      title: locale.t('register_title'),
      description: locale.t('register_intro'),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _username,
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
                controller: _email,
                label: locale.t('email'),
                icon: HugeIcons.strokeRoundedMail01,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return locale.t('required_field');
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                      ? null
                      : locale.t('invalid_email');
                },
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _phone,
                label: locale.t('phone_optional'),
                icon: HugeIcons.strokeRoundedCall,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _password,
                label: locale.t('password'),
                icon: HugeIcons.strokeRoundedLockPassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
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
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: _confirmPassword,
                label: locale.t('register_confirm_password'),
                icon: HugeIcons.strokeRoundedLockPassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                obscureText: !_confirmPasswordVisible,
                onVisibilityPressed: () => setState(
                  () => _confirmPasswordVisible = !_confirmPasswordVisible,
                ),
                visibilityLabel: locale.t(
                  _confirmPasswordVisible ? 'hide_password' : 'show_password',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return locale.t('required_field');
                  }
                  return value == _password.text
                      ? null
                      : locale.t('passwords_dont_match');
                },
                onFieldSubmitted: (_) {
                  if (!auth.isLoading) _submit();
                },
              ),
              const SizedBox(height: 25),
              if (auth.isLoading)
                const SizedBox(
                  height: 54,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                BrandPrimaryButton(
                  onPressed: _submit,
                  label: locale.t('register_button'),
                ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    locale.t('auth_have_account'),
                    style: TextStyle(color: AppColors.bodyText, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    child: Text(locale.t('login_title')),
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
