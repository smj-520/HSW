import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_i18n.dart';
import '../services/otp_service.dart';
import '../services/password_reset_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';

class OtpCodeScreen extends StatefulWidget {
  const OtpCodeScreen({
    super.key,
    required this.email,
    required this.purpose,
    required this.onVerified,
    this.resendCode,
    this.verifyCode,
    this.titleEn = 'Enter the code',
    this.titleAr = 'أدخل الرمز',
    this.subtitleEn =
        'We sent a 6-digit number to your email. It expires in 10 minutes.',
    this.subtitleAr =
        'أرسلنا رقماً من 6 خانات إلى بريدك. ينتهي خلال 10 دقائق.',
  });

  final String email;
  final String purpose;
  final Future<void> Function(String code) onVerified;
  final Future<void> Function()? resendCode;
  final Future<void> Function(String code)? verifyCode;
  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;

  @override
  State<OtpCodeScreen> createState() => _OtpCodeScreenState();
}

class _OtpCodeScreenState extends State<OtpCodeScreen> {
  final _otp = OtpService();
  final _codeCtrl = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  String? _error;
  int _cooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _codeCtrl.addListener(_onCodeChanged);
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
    _timer = Timer.periodic(const Duration(seconds: 1), _tickCooldown);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.removeListener(_onCodeChanged);
    _codeCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _code => _codeCtrl.text.replaceAll(RegExp(r'\D'), '');

  void _tickCooldown(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }
    if (_cooldown <= 1) {
      timer.cancel();
      setState(() => _cooldown = 0);
      return;
    }
    setState(() => _cooldown -= 1);
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), _tickCooldown);
  }

  void _onCodeChanged() {
    final digits = _code;
    if (digits.length > 6) {
      _codeCtrl.value = TextEditingValue(
        text: digits.substring(0, 6),
        selection: const TextSelection.collapsed(offset: 6),
      );
      return;
    }
    if (_error != null) setState(() => _error = null);
    setState(() {});
  }

  Future<void> _verify() async {
    if (_loading) return;
    final code = _code;
    if (code.length != 6) {
      setState(() {
        _error = AppI18n.ts(
          en: 'Enter the 6-digit code.',
          ar: 'أدخل الرمز المكوّن من 6 أرقام.',
        );
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.verifyCode != null) {
        await widget.verifyCode!(code);
      } else {
        await _otp.verifyCode(
          email: widget.email,
          purpose: widget.purpose,
          code: code,
        );
      }
      if (!mounted) return;
      await widget.onVerified(code);
    } on OtpException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
      return;
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppI18n.ts(
          en: 'Could not verify the code.',
          ar: 'تعذر التحقق من الرمز.',
        );
      });
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.resendCode != null) {
        await widget.resendCode!();
      } else {
        await _otp.sendCode(email: widget.email, purpose: widget.purpose);
      }
      if (!mounted) return;
      setState(() => _loading = false);
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(
              context,
              en: 'A new 6-digit code was sent.',
              ar: 'تم إرسال رمز جديد من 6 أرقام.',
            ),
          ),
        ),
      );
    } on OtpException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppI18n.ts(
          en: 'No internet connection. Check your network and try again.',
          ar: 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final code = _code;
    return LoadingOverlay(
      loading: _loading,
      message: AppI18n.t(
        context,
        en: 'Checking code…',
        ar: 'جارٍ التحقق من الرمز...',
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final logoH = (constraints.maxHeight * 0.22).clamp(100.0, 160.0);
            final topPad = MediaQuery.paddingOf(context).top;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: topPad + 48,
                  child: Stack(
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
                  child: ResponsiveScrollableCenter(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      child: AuthFormFrame(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthFormFooterBranding(
                              title: AppI18n.t(
                                context,
                                en: widget.titleEn,
                                ar: widget.titleAr,
                              ),
                              subtitle: AppI18n.t(
                                context,
                                en: '${widget.subtitleEn}\n${widget.email}',
                                ar: '${widget.subtitleAr}\n${widget.email}',
                              ),
                              logoHeight: logoH,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 56,
                              child: Stack(
                                children: [
                                  Row(
                                    children: [
                                      for (var i = 0; i < 6; i++) ...[
                                        if (i > 0) const SizedBox(width: 6),
                                        Expanded(
                                          child: _OtpBox(
                                            digit: i < code.length
                                                ? code[i]
                                                : '',
                                            focused: _focus.hasFocus &&
                                                (code.length == i ||
                                                    (i == 5 &&
                                                        code.length == 6)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Positioned.fill(
                                    child: Opacity(
                                      opacity: 0.01,
                                      child: TextField(
                                        controller: _codeCtrl,
                                        focusNode: _focus,
                                        autofocus: true,
                                        showCursor: false,
                                        enableInteractiveSelection: true,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        style: const TextStyle(
                                          color: Colors.transparent,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          counterText: '',
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(6),
                                        ],
                                        onSubmitted: (_) => _verify(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed:
                                  (_loading || _cooldown > 0) ? null : _resend,
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
                            const SizedBox(height: 8),
                            PrimaryActionButton(
                              label: AppI18n.t(
                                context,
                                en: 'Verify',
                                ar: 'تحقق',
                              ),
                              isLoading: _loading,
                              inlineProgress: false,
                              onPressed: _loading ? null : _verify,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppI18n.t(
                                context,
                                en:
                                    'The email contains only the 6-digit number — no link.',
                                ar:
                                    'البريد يحتوي على الرقم فقط — بدون رابط.',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.62),
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
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

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.digit, required this.focused});

  final String digit;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? const Color(0xFF27AE60) : AppColors.homeAccent.withValues(alpha: 0.35),
          width: focused ? 2 : 1,
        ),
      ),
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
