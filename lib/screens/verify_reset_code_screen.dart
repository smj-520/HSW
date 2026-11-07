import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation/app_transitions.dart';
import '../services/app_i18n.dart';
import '../services/password_reset_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';
import './login_screen.dart';


class VerifyResetCodeScreen extends StatefulWidget {
  const VerifyResetCodeScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _loading = false;
  int _cooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldown = 0);
        return;
      }
      if (mounted) setState(() => _cooldown -= 1);
    });
  }

  String? _codeValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) {
      return AppI18n.t(
        context,
        en: 'Enter the 6-digit code',
        ar: 'أدخل الرمز المكوّن من 6 أرقام',
      );
    }
    return null;
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await PasswordResetService().sendCode(widget.email);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(
              context,
              en: 'Open the reset link in your email to set a new password.',
              ar: 'افتح رابط إعادة التعيين في بريدك لتعيين كلمة مرور جديدة.',
            ),
          ),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        AppTransitions.fadeSlide(
          const LoginScreen(),
          routeName: '/login',
        ),
        (route) => false,
      );
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _loading) return;
    setState(() => _loading = true);
    try {
      await PasswordResetService().sendCode(widget.email);
      if (!mounted) return;
      setState(() => _loading = false);
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(
              context,
              en: 'If an account exists for this email, we sent a reset link',
              ar: 'إذا كان هناك حساب لهذا البريد، أرسلنا رابط إعادة التعيين',
            ),
          ),
        ),
      );
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      message: AppI18n.t(context, en: 'Checking code…', ar: 'جارٍ التحقق من الرمز...'),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    clipBehavior: Clip.antiAlias,
                    child: ResponsiveScrollableCenter(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        child: AuthFormFrame(
                          child: Form(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthFormFooterBranding(
                                  title: AppI18n.t(
                                    context,
                                    en: 'Verify code',
                                    ar: 'تحقق من الرمز',
                                  ),
                                  subtitle: AppI18n.t(
                                    context,
                                    en:
                                        'If an account exists for this email, we sent a code. Enter the 6-digit code (it expires in 10 minutes).',
                                    ar:
                                        'إذا كان هناك حساب لهذا البريد، تم إرسال رمز. أدخل الرمز المكوّن من 6 أرقام (ينتهي خلال 10 دقائق).',
                                  ),
                                  logoHeight: logoH,
                                ),
                                AppTextField(
                                  controller: _code,
                                  label: AppI18n.t(context, en: '6-digit code', ar: 'رمز من 6 أرقام'),
                                  hint: '000000',
                                  prefixIcon: Icons.pin_outlined,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _verify(),
                                  validator: _codeValidator,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: (_loading || _cooldown > 0) ? null : _resend,
                                  child: Text(
                                    _cooldown > 0
                                        ? AppI18n.t(
                                            context,
                                            en: 'Resend code in $_cooldown s',
                                            ar: 'إعادة الإرسال بعد $_cooldown ث',
                                          )
                                        : AppI18n.t(
                                            context,
                                            en: 'Resend code',
                                            ar: 'إعادة إرسال الرمز',
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                PrimaryActionButton(
                                  label: AppI18n.t(context, en: 'Verify', ar: 'تحقق'),
                                  isLoading: _loading,
                                  inlineProgress: false,
                                  onPressed: _loading ? null : _verify,
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
