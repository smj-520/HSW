import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../navigation/app_transitions.dart';
import '../services/app_i18n.dart';
import '../services/auth_error_messages.dart';
import '../services/user_profile_repository.dart';
import '../utils/form_validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/styled_country_phone_field.dart';
import './login_screen.dart';
import './user_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  final String _countryIso = 'OM';

  final _profileRepo = UserProfileRepository();

  @override
  void initState() {
    super.initState();
    _password.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (_confirm.text.isNotEmpty) {
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _password.removeListener(_onPasswordChanged);
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _confirmValidator(String? v) {
    return FormValidators.confirmPassword(_password.text, v);
  }

  String? _phoneValidator(String? v) {
    final iso = FormValidators.tryParseIso(_countryIso);
    if (iso == null) {
      return AppI18n.ts(en: 'Select a country', ar: 'اختر الدولة');
    }
    return FormValidators.phoneNational(v, iso);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final iso = FormValidators.tryParseIso(_countryIso);
    if (iso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(
              context,
              en: 'Select a valid country code.',
              ar: 'اختر رمز دولة صحيح.',
            ),
          ),
        ),
      );
      return;
    }

    final email = FormValidators.normalizeEmail(_email.text);
    final rawPhone = _phone.text.trim().replaceAll(RegExp(r'[\s-]'), '');
    late final String e164;
    try {
      e164 = PhoneNumber.parse(rawPhone, callerCountry: iso).international;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(
              context,
              en: 'Invalid Oman phone number.',
              ar: 'رقم الهاتف العماني غير صحيح.',
            ),
          ),
        ),
      );
      return;
    }
//hashing...
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _password.text,
      );
      final user = cred.user!;
      await user.updateDisplayName(_name.text.trim());
      try {
        await _profileRepo.saveNewUserProfile(
          uid: user.uid,
          displayName: _name.text.trim(),
          email: email,
          phoneE164: e164,
          countryIso: _countryIso.toUpperCase(),
          role: 'user',
        );
      } catch (e) {
        try {
          await user.delete();
        } catch (_) {}
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppI18n.t(
                context,
                en: 'Could not save profile: $e',
                ar: 'تعذر حفظ الملف الشخصي: $e',
              ),
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const UserHomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(e))));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const UserHomeScreen()),
          (route) => false,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      message: AppI18n.t(
        context,
        en: 'Creating your account…',
        ar: 'جارٍ إنشاء حسابك...',
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
                                    en: 'Create your Account',
                                    ar: 'إنشاء حسابك',
                                  ),
                                  subtitle: AppI18n.t(
                                    context,
                                    en: 'Any Email • Oman (+968) • Strong password required',
                                    ar: ' اي بريد الكتروني • عُمان (+968) • كلمة مرور قوية مطلوبة',
                                  ),
                                  logoHeight: logoH,
                                ),
                                AppTextField(
                                  controller: _name,
                                  label: AppI18n.t(
                                    context,
                                    en: 'Full Name',
                                    ar: 'الاسم الكامل',
                                  ),
                                  hint: AppI18n.t(
                                    context,
                                    en: 'Your full name',
                                    ar: 'اسمك الكامل',
                                  ),
                                  prefixIcon: Icons.person_outline_rounded,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  validator: (v) => FormValidators.required(
                                    v,
                                    fieldEn: 'Name',
                                    fieldAr: 'الاسم',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _email,
                                  label: AppI18n.t(
                                    context,
                                    en: 'Email',
                                    ar: 'البريد الالكتروني',
                                  ),
                                  hint: AppI18n.t(
                                    context,
                                    en: 'example@email.com',
                                    ar: 'example@email.com',
                                  ),
                                  prefixIcon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: FormValidators.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                StyledCountryPhoneField(
                                  phoneController: _phone,
                                  selectedIsoCode: _countryIso,
                                  onCountryChanged: (_) {},
                                  fixedCountryOnly: true,
                                  fixedCountryLabel: AppI18n.t(
                                    context,
                                    en: 'Oman',
                                    ar: 'عُمان',
                                  ),
                                  fixedDialCode: '+968',
                                  validator: _phoneValidator,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _password,
                                  label: AppI18n.t(
                                    context,
                                    en: 'Password',
                                    ar: 'كلمة المرور',
                                  ),
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePass,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  validator: FormValidators.strongPassword,
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                          () => _obscurePass = !_obscurePass,
                                    ),
                                    icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 6,
                                    left: 2,
                                    right: 2,
                                  ),
                                  child: Text(
                                    FormValidators.passwordPolicyHint(),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.68),
                                      height: 1.35,
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
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: _confirmValidator,
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                          () => _obscureConfirm = !_obscureConfirm,
                                    ),
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
                                const SizedBox(height: 24),
                                PrimaryActionButton(
                                  label: AppI18n.t(
                                    context,
                                    en: 'Register',
                                    ar: 'تسجيل',
                                  ),
                                  isLoading: _loading,
                                  inlineProgress: false,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                      Navigator.of(
                                        context,
                                      ).pushReplacement(
                                        AppTransitions.fadeSlide(
                                          const LoginScreen(),
                                          routeName: '/login',
                                        ),
                                      );
                                    },
                                    child: Text(
                                      AppI18n.t(
                                        context,
                                        en: 'Already have an account? Login',
                                        ar: 'لديك حساب بالفعل؟ تسجيل الدخول',
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
