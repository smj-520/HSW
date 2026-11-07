import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../navigation/app_transitions.dart';
import '../services/app_i18n.dart';
import '../services/app_settings_controller.dart';
import '../services/remember_credentials.dart';
import '../services/auth_error_messages.dart';
import '../services/user_profile_repository.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/form_validators.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/app_text_field.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/styled_country_phone_field.dart';
import './about_application_page.dart';
import './ai_chatbot_screen.dart';
import './login_screen.dart';
import './send_feedback_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              widget.isAdmin
                  ? context.tr('Admin Settings', 'إعدادات المدير')
                  : context.tr('User Settings', 'إعدادات المستخدم'),
            ),
          ),
          body: ResponsiveContent(
                  child: ListView(
                    padding: EdgeInsets.all(
                      responsivePagePaddingX(MediaQuery.sizeOf(context).width),
                    ),
                    children: [
                AnimatedAppear(
                  index: 0,
                  child: _sectionCard(
                    title: context.tr('Account', 'الحساب'),
                    child: _optionTile(
                      icon: Icons.person_outline_rounded,
                      title: context.tr('Profile settings', 'إعدادات الملف الشخصي'),
                      subtitle: context.tr(
                        'Update name and Oman phone number',
                        'تعديل الاسم ورقم الهاتف (عمان)',
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          AppTransitions.fadeSlideSheet(
                            const _ProfileSettingsPage(),
                            routeName: '/settings/profile',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (!widget.isAdmin) ...[
                  const SizedBox(height: 12),
                  AnimatedAppear(
                    index: 0,
                    child: _sectionCard(
                      title: context.tr('Feedback', 'ملاحظات'),
                      child: _optionTile(
                        icon: Icons.rate_review_outlined,
                        title: context.tr('Send feedback', 'إرسال ملاحظات'),
                        subtitle: context.tr(
                          'Tell the admin what you think',
                          'أخبر المدير برأيك',
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SendFeedbackScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AnimatedAppear(
                  index: 1,
                  child: _sectionCard(
                    title: context.tr('Security', 'الأمان'),
                    child: _optionTile(
                      icon: Icons.lock_reset_rounded,
                      title: context.tr('Change password', 'تغيير كلمة المرور'),
                      subtitle: context.tr(
                        'Open secure password update form',
                        'فتح نموذج آمن لتحديث كلمة المرور',
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          AppTransitions.fadeSlideSheet(
                            const _PasswordSettingsPage(),
                            routeName: '/settings/password',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedAppear(
                  index: 2,
                  child: _sectionCard(
                    title: context.tr('Appearance & Language', 'المظهر واللغة'),
                    child: _optionTile(
                      icon: Icons.tune_rounded,
                      title: context.tr('Display & language', 'العرض واللغة'),
                      subtitle: context.tr(
                        'Toggle dark mode and app language',
                        'تفعيل/تعطيل الوضع الداكن وتبديل اللغة',
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          AppTransitions.fadeSlideSheet(
                            const _AppearanceLanguagePage(),
                            routeName: '/settings/appearance',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (!widget.isAdmin) ...[
                  const SizedBox(height: 12),
                  AnimatedAppear(
                    index: 3,
                    child: _sectionCard(
                      title: context.tr('Assistant', 'المساعد'),
                      child: _optionTile(
                        icon: Icons.smart_toy_outlined,
                        title: AppI18n.t(
                          context,
                          en: 'AI Chatbot',
                          ar: 'محادثة الذكاء الاصطناعي',
                        ),
                        subtitle: AppI18n.t(
                          context,
                          en: 'Open the assistant (integration ready)',
                          ar: 'فتح المساعد (جاهز للربط)',
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            AppTransitions.fadeSlideSheet(
                              const AiChatbotScreen(),
                              routeName: '/settings/chatbot',
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AnimatedAppear(
                  index: widget.isAdmin ? 3 : 4,
                  child: _sectionCard(
                    title: context.tr('More', 'المزيد'),
                    child: Column(
                      children: [
                        _optionTile(
                          icon: Icons.privacy_tip_outlined,
                          title: context.tr('Privacy & Terms', 'الخصوصية والشروط'),
                          subtitle: context.tr(
                            'Read data handling and app terms',
                            'قراءة سياسة الخصوصية وشروط الاستخدام',
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              AppTransitions.fadeSlideSheet(
                                const _PrivacyPage(),
                                routeName: '/settings/privacy',
                              ),
                            );
                          },
                        ),
                        _optionTile(
                          icon: Icons.info_outline_rounded,
                          title: context.tr('About application', 'حول التطبيق'),
                          subtitle: context.tr(
                            'Version, purpose and support details',
                            'الإصدار، الهدف، وبيانات الدعم',
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              AppTransitions.fadeSlideSheet(
                                AboutApplicationPage(isAdmin: widget.isAdmin),
                                routeName: '/settings/about',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedAppear(
                  index: widget.isAdmin ? 4 : 5,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final confirm = await showGeneralDialog<bool>(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: MaterialLocalizations.of(context)
                              .modalBarrierDismissLabel,
                          barrierColor: Colors.black45,
                          transitionDuration:
                              const Duration(milliseconds: 240),
                          pageBuilder: (ctx, anim, secAnim) {
                            final scheme = Theme.of(ctx).colorScheme;
                            final isDark =
                                Theme.of(ctx).brightness == Brightness.dark;
                            return AlertDialog(
                              title: Text(context.tr(
                                  'Confirm logout', 'تأكيد تسجيل الخروج')),
                              content: Text(
                                context.tr(
                                  'Are you sure you want to logout?',
                                  'هل أنت متأكد أنك تريد تسجيل الخروج؟',
                                ),
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              actions: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: scheme.onSurface,
                                          backgroundColor:
                                              scheme.surfaceContainerHigh,
                                          side: BorderSide(
                                            color: scheme.outline.withValues(
                                              alpha: isDark ? 0.95 : 0.85,
                                            ),
                                            width: 1.6,
                                          ),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 22,
                                            vertical: 12,
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(
                                            context.tr('Cancel', 'إلغاء')),
                                      ),
                                      const SizedBox(width: 28),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 22,
                                            vertical: 12,
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(context.tr(
                                            'Logout', 'تسجيل الخروج')),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                          transitionBuilder: (ctx, anim, secAnim, child) {
                            final curved = CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            );
                            return FadeTransition(
                              opacity: curved,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.96, end: 1)
                                    .animate(curved),
                                child: child,
                              ),
                            );
                          },
                        );
                        if (confirm != true || !mounted) return;
                        await RememberCredentials.clearStoredSecrets();
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        navigator.pushAndRemoveUntil(
                          AppTransitions.fadeSlide(
                            const LoginScreen(),
                            routeName: '/login',
                          ),
                          (route) => false,
                        );
                      },
                      child:
                          Text(context.tr('Logout', 'تسجيل الخروج')),
                    ),
                  ),
                ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
    );
  }
}

class _ProfileSettingsPage extends StatefulWidget {
  const _ProfileSettingsPage();

  @override
  State<_ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<_ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _repo = UserProfileRepository();
  bool _loading = false;
  String? _photoUrl;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.success, content: Text(message)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.error, content: Text(message)),
    );
  }

  Future<void> _loadProfile() async {
    final user = _user;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final profile = await _repo.getUserProfile(user.uid);
      if (!mounted) return;
      _name.text = (profile?['displayName'] as String?) ?? user.displayName ?? '';
      _email.text = user.email ?? '';
      _photoUrl = (profile?['photoUrl'] as String?) ?? user.photoURL;
      final phone = (profile?['phoneE164'] as String?) ?? '';
      _phone.text = phone.startsWith('+968')
          ? phone.replaceFirst('+968', '').trim()
          : phone;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _phoneValidator(String? v) {
    return FormValidators.phoneNational(v, IsoCode.OM);
  }

  Future<void> _save() async {
    final user = _user;
    if (user == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phoneRaw = _phone.text.trim().replaceAll(RegExp(r'[\s-]'), '');
    setState(() => _loading = true);
    try {
      final phoneE164 =
          PhoneNumber.parse(phoneRaw, callerCountry: IsoCode.OM).international;
      await user.updateDisplayName(_name.text.trim());
      await _repo.updateProfileBasics(
        uid: user.uid,
        displayName: _name.text.trim(),
        phoneE164: phoneE164,
        countryIso: 'OM',
        photoUrl: _photoUrl,
      );
      if (!mounted) return;
      _showSuccess(context.tr('Profile updated successfully.', 'تم تحديث الملف الشخصي بنجاح.'));
    } catch (e) {
      if (!mounted) return;
      _showError(context.tr('Failed to update profile: $e', 'فشل تحديث الملف الشخصي: $e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      message: context.tr('Saving profile…', 'جارٍ حفظ الملف الشخصي...'),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text(context.tr('Profile settings', 'إعدادات الملف الشخصي'))),
        body: AnimatedPageContent(
          duration: const Duration(milliseconds: 380),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _name,
                      label: context.tr('Full Name', 'الاسم الكامل'),
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) => FormValidators.required(
                        v,
                        fieldEn: 'Name',
                        fieldAr: 'الاسم',
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _email,
                      label: context.tr(
                          'Email (read only)', 'الإيميل (قراءة فقط)'),
                      prefixIcon: Icons.mail_outline_rounded,
                      readOnly: true,
                    ),
                    const SizedBox(height: 14),
                    StyledCountryPhoneField(
                      phoneController: _phone,
                      selectedIsoCode: 'OM',
                      onCountryChanged: (_) {},
                      fixedCountryOnly: true,
                      fixedCountryLabel: context.tr('Oman', 'عمان'),
                      fixedDialCode: '+968',
                      validator: _phoneValidator,
                    ),
                    const SizedBox(height: 16),
                    PrimaryActionButton(
                      label: context.tr('Save profile', 'حفظ الملف الشخصي'),
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordSettingsPage extends StatefulWidget {
  const _PasswordSettingsPage();

  @override
  State<_PasswordSettingsPage> createState() => _PasswordSettingsPageState();
}

class _PasswordSettingsPageState extends State<_PasswordSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPass = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _passwordUpdatedAtIso;
  final _profileRepo = UserProfileRepository();

  @override
  void initState() {
    super.initState();
    _newPass.addListener(_onNewPassChanged);
    _loadPasswordMeta();
  }

  Future<void> _loadPasswordMeta() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final profile = await _profileRepo.getUserProfile(user.uid);
      if (!mounted) return;
      final raw = profile?['passwordUpdatedAt'];
      if (raw is String && raw.isNotEmpty) {
        setState(() => _passwordUpdatedAtIso = raw);
      }
    } catch (_) {
    }
  }

  void _onNewPassChanged() {
    if (_confirm.text.isNotEmpty) {
      _formKey.currentState?.validate();
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.success, content: Text(message)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.error, content: Text(message)),
    );
  }

  @override
  void dispose() {
    _newPass.removeListener(_onNewPassChanged);
    _oldPass.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _confirmValidator(String? v) {
    return FormValidators.confirmPassword(_newPass.text, v);
  }

  String? _newPassValidator(String? v) {
    final p = FormValidators.strongPassword(v);
    if (p != null) return p;
    return FormValidators.newPasswordDifferent(
      newPassword: v,
      oldPassword: _oldPass.text,
    );
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final email = user.email;
      if (email == null || email.isEmpty) {
        _showError(context.tr('Missing user email for verification.', 'البريد غير متوفر للتحقق.'));
        return;
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _oldPass.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPass.text);
      await _profileRepo.touchPasswordUpdated(user.uid);
      _oldPass.clear();
      _newPass.clear();
      _confirm.clear();
      if (!mounted) return;
      await _loadPasswordMeta();
      if (!mounted) return;
      _showSuccess(context.tr('Password changed successfully.', 'تم تغيير كلمة المرور بنجاح.'));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      message: context.tr('Updating password…', 'جارٍ تحديث كلمة المرور...'),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text(context.tr('Change password', 'تغيير كلمة المرور'))),
        body: AnimatedPageContent(
          duration: const Duration(milliseconds: 380),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_passwordUpdatedAtIso != null &&
                  _passwordUpdatedAtIso!.isNotEmpty) ...[
                Text(
                  context.tr(
                    'Last password update',
                    'آخر تحديث لكلمة المرور',
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppDateFormat.formatIsoUtcForDisplay(
                    context,
                    _passwordUpdatedAtIso,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
                      ),
                ),
                const SizedBox(height: 20),
              ],
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _oldPass,
                      label: context.tr('Old Password', 'كلمة المرور الحالية'),
                      prefixIcon: Icons.password_rounded,
                      obscureText: _obscureOld,
                      validator: FormValidators.loginPassword,
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _obscureOld = !_obscureOld),
                        icon: Icon(
                          _obscureOld
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _newPass,
                      label: context.tr('New Password', 'كلمة المرور الجديدة'),
                      prefixIcon: Icons.lock_reset_rounded,
                      obscureText: _obscureNew,
                      validator: _newPassValidator,
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
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
                      child: Text(
                        FormValidators.passwordPolicyHint(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.68),
                              height: 1.35,
                            ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _confirm,
                      label: context.tr('Confirm Password', 'تأكيد كلمة المرور'),
                      prefixIcon: Icons.verified_outlined,
                      obscureText: _obscureConfirm,
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
                    const SizedBox(height: 16),
                    PrimaryActionButton(
                      label: context.tr('Save password', 'حفظ كلمة المرور'),
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearanceLanguagePage extends StatefulWidget {
  const _AppearanceLanguagePage();

  @override
  State<_AppearanceLanguagePage> createState() => _AppearanceLanguagePageState();
}

class _AppearanceLanguagePageState extends State<_AppearanceLanguagePage> {
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.success, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final darkOn = settings.themeMode == ThemeMode.dark;
        final arabicOn = settings.locale.languageCode == 'ar';
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(title: Text(context.tr('Display & language', 'العرض واللغة'))),
          body: AnimatedPageContent(
            duration: const Duration(milliseconds: 340),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(
                  darkOn ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(context.tr('Dark mode', 'الوضع الداكن')),
                subtitle: Text(
                  darkOn
                      ? context.tr('Enabled', 'مفعل')
                      : context.tr('Disabled', 'غير مفعل'),
                ),
                trailing: IconButton(
                  icon: Icon(
                    darkOn ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                    color: darkOn ? AppColors.success : AppColors.error,
                    size: 36,
                  ),
                  onPressed: () {
                    final next = darkOn ? ThemeMode.light : ThemeMode.dark;
                    settings.setThemeMode(next);
                    _showSuccess(
                      next == ThemeMode.dark
                          ? context.tr('Dark mode enabled.', 'تم تفعيل الوضع الداكن.')
                          : context.tr('Light mode enabled.', 'تم تفعيل الوضع الفاتح.'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(
                  Icons.language_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(context.tr('Arabic language', 'اللغة العربية')),
                subtitle: Text(
                  arabicOn
                      ? context.tr('Enabled', 'مفعلة')
                      : context.tr('Disabled', 'غير مفعلة'),
                ),
                trailing: IconButton(
                  icon: Icon(
                    arabicOn ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                    color: arabicOn ? AppColors.success : AppColors.error,
                    size: 36,
                  ),
                  onPressed: () {
                    final nextLang = arabicOn ? 'en' : 'ar';
                    settings.setLanguage(nextLang);
                    _showSuccess(
                      nextLang == 'ar'
                          ? context.tr(
                              'Arabic language enabled.',
                              'تم تفعيل اللغة العربية.',
                            )
                          : context.tr(
                              'English language enabled.',
                              'تم تفعيل اللغة الإنجليزية.',
                            ),
                    );
                  },
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('Privacy & Terms', 'الخصوصية والشروط')),
      ),
      body: AnimatedPageContent(
        duration: const Duration(milliseconds: 340),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              AppI18n.t(
                context,
                en:
                    'We store only essential account data (name, email, phone, role) to run the app experience.',
                ar:
                    'نحن نحفظ بيانات الحساب الأساسية فقط (الاسم، البريد، الهاتف، الدور) لتحسين تجربة التطبيق.',
              ),
            ),
          const SizedBox(height: 10),
          Text(
            AppI18n.t(
              context,
              en:
                  'Passwords are never stored in app database; they are securely managed by Firebase Authentication.',
              ar:
                  'كلمات المرور لا تُخزن في قاعدة بيانات التطبيق، ويتم إدارتها آمنًا عبر Firebase Authentication.',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppI18n.t(
              context,
              en:
                  'By using this app, you agree to use of data for functional purposes only.',
              ar:
                  'باستخدام التطبيق فأنت توافق على استخدام البيانات للأغراض الوظيفية فقط.',
            ),
          ),
          ],
        ),
      ),
    );
  }
}

