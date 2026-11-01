import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../navigation/app_transitions.dart';
import '../services/app_i18n.dart';
import '../services/auth_error_messages.dart';
import '../services/remember_credentials.dart';
import '../services/user_profile_repository.dart';
import '../utils/form_validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';
import '../services/admin_services.dart';
import './forgot_password_screen.dart';
import './register_screen.dart';
import './user_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;
  bool _loading = false;
  final _profileRepo = UserProfileRepository();
  final _adminAuth = AdminAuthService();

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    final enabled = await RememberCredentials.loadEnabled();
    final user = await RememberCredentials.loadGmailUsername();
    final pass = await RememberCredentials.loadPasswordIfRemembered();
    if (!mounted) return;
    setState(() {
      _remember = enabled;
      if (enabled && user.isNotEmpty) {
        _email.text = user;
      }
      if (enabled && pass != null && pass.isNotEmpty) {
        _password.text = pass;
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final email = FormValidators.normalizeEmail(_email.text);
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _password.text,
      );
      final signedIn = FirebaseAuth.instance.currentUser;
      if (signedIn != null) {
        final blocked = await _profileRepo.isBlocked(signedIn.uid);
        if (blocked) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppI18n.t(
                  context,
                  en: 'Your account has been blocked',
                  ar: 'تم حظر حسابك',
                ),
              ),
            ),
          );
          return;
        }
        await _profileRepo.touchLastLogin(signedIn.uid);
      }
      await RememberCredentials.saveAfterLogin(
        remember: _remember,
        gmailUsername: email,
        password: _password.text,
      );
      if (!mounted) return;
      await _openHomeForSignedInUser();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Looks at the database role, then opens Admin Home or User Home.
  Future<void> _openHomeForSignedInUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final role = await _adminAuth.getRole(user.uid);
    if (!mounted) return;
    if (_adminAuth.isAdmin(role)) {
      _openAdminHome();
    } else {
      _openUserHome();
    }
  }

  // Replaces login with Admin Home. Back cannot return to login.
  void _openAdminHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
  }

  // Replaces login with the normal user Home. Back cannot return to login.
  void _openUserHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const UserHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      message: AppI18n.t(
        context,
        en: 'Signing you in…',
        ar: 'جارٍ تسجيل الدخول...',
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
                                    en: 'Welcome back',
                                    ar: 'مرحبًا بعودتك',
                                  ),
                                  subtitle: AppI18n.t(
                                    context,
                                    en: 'Sign in with your email and password',
                                    ar: 'سجّل الدخول بالبريد وكلمة المرور',
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
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: FormValidators.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _password,
                                  label: AppI18n.t(
                                    context,
                                    en: 'Password',
                                    ar: 'كلمة المرور',
                                  ),
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: FormValidators.loginPassword,
                                  suffix: IconButton(
                                    tooltip: _obscure
                                        ? AppI18n.t(
                                            context,
                                            en: 'Show password',
                                            ar: 'إظهار كلمة المرور',
                                          )
                                        : AppI18n.t(
                                            context,
                                            en: 'Hide password',
                                            ar: 'إخفاء كلمة المرور',
                                          ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _remember,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (v) => setState(
                                        () => _remember = v ?? false,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        AppI18n.t(
                                          context,
                                          en: 'Remember Me',
                                          ar: 'تذكرني',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                            ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () {
                                              Navigator.of(context).push(
                                                AppTransitions.fadeSlide(
                                                  const ForgotPasswordScreen(),
                                                  routeName: '/forgot',
                                                ),
                                              );
                                            },
                                      child: Text(
                                        AppI18n.t(
                                          context,
                                        en: 'Forgot password?',
                                        ar: 'نسيت كلمة المرور؟',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                PrimaryActionButton(
                                  label: AppI18n.t(
                                    context,
                                    en: 'Login',
                                    ar: 'تسجيل الدخول',
                                  ),
                                  isLoading: _loading,
                                  inlineProgress: false,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              AppTransitions.fadeSlide(
                                                const RegisterScreen(),
                                                routeName: '/register',
                                              ),
                                            );
                                          },
                                    child: Text(
                                      AppI18n.t(
                                        context,
                                        en: "Don't have an account?",
                                        ar: 'ليس لديك حساب؟',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.72),
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.none,
                                          ),
                                    ),
                                  ),
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
