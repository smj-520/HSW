import 'package:flutter/material.dart';
import '../navigation/app_transitions.dart';
import '../services/app_i18n.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/hostel_brand.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';
import './login_screen.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  void _toLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      AppTransitions.fadeSlide(
        const LoginScreen(),
        routeName: '/login',
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: HostelBrandAppBar(
        onBack: () => _toLogin(context),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveScrollableCenter(
          child: AnimatedPageContent(
            child: Column(
              children: [
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.06),
                          blurRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: scheme.primary,
                      size: 88,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  AppI18n.t(
                    context,
                    en: 'saved successfully!',
                    ar: 'تم الحفظ بنجاح!',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                ),
                const SizedBox(height: 36),
                PrimaryActionButton(
                  label: AppI18n.t(
                    context,
                    en: 'Back to Login',
                    ar: 'العودة لتسجيل الدخول',
                  ),
                  onPressed: () => _toLogin(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
