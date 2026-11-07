import 'package:flutter/material.dart';

import '../navigation/app_transitions.dart';
import '../services/app_i18n.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/auth_widgets.dart';
import './login_screen.dart';
import './register_screen.dart';
import './splash_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _backToSplash(BuildContext context) {
    Navigator.of(context).pushReplacement(
      AppTransitions.fade(const SplashScreen(), routeName: '/splash'),
    );
  }

  void _goLogin(BuildContext context) {
    Navigator.of(context).push(
      AppTransitions.fadeSlide(const LoginScreen(), routeName: '/login'),
    );
  }

  void _goRegister(BuildContext context) {
    Navigator.of(context).push(
      AppTransitions.fadeSlide(const RegisterScreen(), routeName: '/register'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final illoH = (mq.shortestSide * 0.38).clamp(168.0, 248.0);
    final maxCol = responsiveFormMaxWidth(mq.width);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedPageContent(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padX = responsivePagePaddingX(constraints.maxWidth);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(padX, 4, padX, 0),
                    child: Row(
                      children: [
                        RoundedBackButton(
                          onPressed: () => _backToSplash(context),
                          tooltip: AppI18n.t(context, en: 'Back', ar: 'رجوع'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxCol),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: padX),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              GentlePulse(
                                child: SizedBox(
                                  height: illoH,
                                  width: double.infinity,
                                  child: Image.asset(
                                    'assets/branding/onboarding_hero.png',
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    semanticLabel: AppI18n.t(
                                      context,
                                      en: 'Budgets and financial goals illustration',
                                      ar: 'رسم توضيحي للميزانيات والأهداف المالية',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                AppI18n.t(
                                  context,
                                  en: 'Set budgets',
                                  ar: 'حدد ميزانياتك',
                                ),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontSize: mq.width >= 600 ? 28 : 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppI18n.t(
                                  context,
                                  en: 'Reach your financial goals',
                                  ar: 'حقق أهدافك المالية',
                                ),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppI18n.t(
                                  context,
                                  en: 'Plan spending, save smarter, and stay in control of hostel life.',
                                  ar: 'خطط مصروفاتك وادخر بذكاء وابقَ مسيطرًا على مصاريف السكن.',
                                ),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              PrimaryActionButton(
                                label: AppI18n.t(
                                  context,
                                  en: 'Create Account',
                                  ar: 'إنشاء حساب',
                                ),
                                onPressed: () => _goRegister(context),
                              ),
                              const SizedBox(height: 12),
                              PrimaryActionButton(
                                label: AppI18n.t(
                                  context,
                                  en: 'Login',
                                  ar: 'تسجيل الدخول',
                                ),
                                onPressed: () => _goLogin(context),
                              ),
                              const SizedBox(height: 20),
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
      ),
    );
  }
}
