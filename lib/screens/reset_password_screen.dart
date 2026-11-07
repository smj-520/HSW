import 'package:flutter/material.dart';

import '../navigation/app_transitions.dart';
import './success_screen.dart';
import '../services/app_i18n.dart';
import '../services/password_reset_service.dart';
import '../utils/form_validators.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/app_text_field.dart';
import '../widgets/hostel_brand.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.recoveryEmail,
    this.previousPassword,
    this.otpCode,
  });

  final String? recoveryEmail;
  final String? previousPassword;
  final String? otpCode;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _newPass.addListener(_onNewPassChanged);
  }

  void _onNewPassChanged() {
    if (_confirm.text.isNotEmpty) {
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _newPass.removeListener(_onNewPassChanged);
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _newPasswordValidator(String? value) {
    final strong = FormValidators.strongPassword(value);
    if (strong != null) return strong;
    return FormValidators.newPasswordDifferent(
      newPassword: value,
      oldPassword: widget.previousPassword,
    );
  }

  String? _confirmValidator(String? v) {
    return FormValidators.confirmPassword(_newPass.text, v);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = widget.recoveryEmail?.trim() ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(
              context,
              en: 'Open Forgot password and enter the 6-digit email code first.',
              ar: 'افتح نسيت كلمة المرور وأدخل رمز البريد أولاً.',
            ),
          ),
        ),
      );
      return;
    }
    final code = widget.otpCode?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(
              context,
              en: 'Verify the 6-digit email code first.',
              ar: 'تحقق أولاً من رمز البريد المكوّن من 6 أرقام.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await PasswordResetService().resetPassword(
        email: email,
        code: code,
        newPassword: _newPass.text,
      );
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        AppTransitions.fadeSlide(
          const SuccessScreen(),
          routeName: '/reset-success',
        ),
        (route) => false,
      );
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      message: AppI18n.t(
        context,
        en: 'Updating password…',
        ar: 'جارٍ تحديث كلمة المرور...',
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: const HostelBrandAppBar(),
        body: SafeArea(
          top: false,
          child: ResponsiveScrollableCenter(
            child: AnimatedPageContent(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      AppI18n.t(context, en: 'Reset Password', ar: 'إعادة تعيين كلمة المرور'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (widget.recoveryEmail != null &&
                        widget.recoveryEmail!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.recoveryEmail!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.72),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      AppI18n.t(context, en: 'Enter New Password', ar: 'أدخل كلمة المرور الجديدة'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppI18n.t(
                        context,
                        en:
                            'Use at least 8 characters with uppercase, lowercase, a number, and a symbol. It must differ from your previous password.',
                        ar:
                            'استخدم 8 أحرف على الأقل مع حرف كبير وصغير ورقم ورمز، وتكون مختلفة عن كلمة المرور السابقة.',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      FormValidators.passwordPolicyHint(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.68),
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _newPass,
                      label: AppI18n.t(
                        context,
                        en: 'New Password',
                        ar: 'كلمة المرور الجديدة',
                      ),
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: _newPasswordValidator,
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirm,
                      label: AppI18n.t(
                        context,
                        en: 'Confirm Password',
                        ar: 'تأكيد كلمة المرور',
                      ),
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: _confirmValidator,
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryActionButton(
                      label: AppI18n.t(context, en: 'Save', ar: 'حفظ'),
                      isLoading: _loading,
                      inlineProgress: false,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
