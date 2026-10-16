import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _saving = false;
  bool _submitted = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _error;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final locale = context.read<LocaleProvider>();
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await _authService.changePassword(
        oldPassword: _oldPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.t('password_changed'))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearError(String _) {
    if (_error != null) setState(() => _error = null);
  }

  Widget _passwordField({
    required LocaleProvider locale,
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    required TextInputAction action,
    required Iterable<String> autofillHints,
    required String? Function(String?) validator,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: action,
      autofillHints: autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      enabled: !_saving,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const HugeIcon(
          icon: HugeIcons.strokeRoundedLockPassword,
          color: AppColors.accent,
          size: 21,
        ),
        suffixIcon: IconButton(
          tooltip: locale.t(visible ? 'hide_password' : 'show_password'),
          onPressed: _saving ? null : onToggle,
          icon: HugeIcon(
            icon: visible
                ? HugeIcons.strokeRoundedEyeOff
                : HugeIcons.strokeRoundedEye,
            color: AppColors.bodyText,
            size: 21,
          ),
        ),
      ),
      validator: validator,
      onChanged: _clearError,
      onFieldSubmitted: onSubmitted,
    );
  }

  Widget _formCard({
    required String number,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.subtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientEnd.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.headingText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description,
              style: TextStyle(color: AppColors.bodyText, height: 1.4)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(locale.t('change_password')),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.softGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.17),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedShieldKey,
                          color: Colors.white,
                          size: 29,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale.t('password_security_title'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              locale.t('password_security_body'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _formCard(
                  number: '01',
                  title: locale.t('current_password'),
                  description: locale.t('password_current_hint'),
                  child: _passwordField(
                    locale: locale,
                    controller: _oldPassword,
                    label: locale.t('current_password'),
                    visible: _showOldPassword,
                    onToggle: () =>
                        setState(() => _showOldPassword = !_showOldPassword),
                    action: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    validator: (value) => (value?.isEmpty ?? true)
                        ? locale.t('required_field')
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                _formCard(
                  number: '02',
                  title: locale.t('new_password'),
                  description: locale.t('password_new_hint'),
                  child: Column(
                    children: [
                      _passwordField(
                        locale: locale,
                        controller: _newPassword,
                        label: locale.t('new_password'),
                        visible: _showNewPassword,
                        onToggle: () => setState(
                            () => _showNewPassword = !_showNewPassword),
                        action: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) => (value?.isEmpty ?? true)
                            ? locale.t('required_field')
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _passwordField(
                        locale: locale,
                        controller: _confirmPassword,
                        label: locale.t('confirm_password'),
                        visible: _showConfirmPassword,
                        onToggle: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword),
                        action: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return locale.t('required_field');
                          }
                          if (value != _newPassword.text) {
                            return locale.t('passwords_dont_match');
                          }
                          return null;
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedAlertCircle,
                            color: AppColors.danger,
                            size: 21,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.subtle)),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 564),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(locale.t('saving')),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(locale.t('change_password')),
                            const SizedBox(width: 10),
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
