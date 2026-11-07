import 'package:flutter/material.dart';

import '../navigation/app_transitions.dart';
import '../services/app_i18n.dart';
import '../services/otp_service.dart';
import '../services/password_reset_service.dart';
import '../utils/form_validators.dart';
import './otp_code_screen.dart';
import './reset_password_screen.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = FormValidators.normalizeEmail(_email.text);
    setState(() => _loading = true);
    try {
      await PasswordResetService().sendCode(email);
      if (!mounted) return;
      await Navigator.of(context).push(
        AppTransitions.fadeSlide(
          OtpCodeScreen(
            email: email,
            purpose: OtpService.resetPurpose,
            titleEn: 'Enter the code',
            titleAr: 'أدخل الرمز',
            resendCode: () => PasswordResetService().sendCode(email),
            verifyCode: (_) async {},
            onVerified: (code) async {
              if (!mounted) return;
              await Navigator.of(context).pushReplacement(
                AppTransitions.fadeSlide(
                  ResetPasswordScreen(
                    recoveryEmail: email,
                    otpCode: code,
                  ),
                  routeName: '/reset-password',
                ),
              );
            },
          ),
          routeName: '/forgot/otp',
        ),
      );
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(
              context,
              en: 'Could not send the email. Try again.',
              ar: 'تعذر إرسال البريد. حاول مرة أخرى.',
            ),
          ),
        ),
      );
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
        en: 'Sending your 6-digit code…',
        ar: 'جارٍ إرسال الرمز...',
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final logoH = (constraints.maxHeight * 0.26).clamp(120.0, 185.0);
            final topPad = MediaQuery.paddingOf(context).top;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: topPad + 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: topPad + 4,
                        left: 8,
                        child: RoundedBackButton(
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Material(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ResponsiveScrollableCenter(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        child: AuthFormFrame(
                          child: Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthFormFooterBranding(
                                  title: AppI18n.t(
                                    context,
                                    en: 'Forgot password?',
                                    ar: 'نسيت كلمة المرور؟',
                                  ),
                                  subtitle: AppI18n.t(
                                    context,
                                    en:
                                        'Enter your email. If an account exists, we send a 6-digit code. No link.',
                                    ar:
                                        'أدخل بريدك — سنرسل رمزاً من 6 أرقام. بدون رابط.',
                                  ),
                                  logoHeight: logoH,
                                ),
                                AppTextField(
                                  controller: _email,
                                  label: AppI18n.t(
                                    context,
                                    en: 'Email',
                                    ar: 'البريد الإلكتروني',
                                  ),
                                  hint: AppI18n.t(
                                    context,
                                    en: 'you@example.com',
                                    ar: 'you@example.com',
                                  ),
                                  prefixIcon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: FormValidators.emailAddress,
                                ),
                                const SizedBox(height: 28),
                                PrimaryActionButton(
                                  label: AppI18n.t(
                                    context,
                                    en: 'Send',
                                    ar: 'إرسال',
                                  ),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
