import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation/app_transitions.dart';
import '../services/app_i18n.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';
import './onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heroController;
  late final Animation<double> _heroScale;
  Timer? _autoNavigate;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _heroScale = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutBack,
    );
    _autoNavigate = Timer(const Duration(seconds: 30), _goOnboarding);
  }

  void _goOnboarding() {
    if (!mounted || _didNavigate) return;
    _didNavigate = true;
    Navigator.of(context).pushReplacement(
      AppTransitions.fade(const OnboardingScreen(), routeName: '/onboarding'),
    );
  }

  @override
  void dispose() {
    _autoNavigate?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final pad = responsivePagePaddingX(w);
            final maxCard = responsiveFormMaxWidth(w).clamp(320.0, w - pad * 2);
            final heroH = (constraints.maxHeight * 0.32).clamp(140.0, 260.0);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  ScaleTransition(
                    scale: _heroScale,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxCard,
                          maxHeight: heroH,
                        ),
                        child: Image.asset(
                          'assets/branding/splash_wallet_hero.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          semanticLabel: AppI18n.t(
                            context,
                            en: 'Hostel Student Wallet logo',
                            ar: 'شعار محفظة الطالب السكنية',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppI18n.t(
                      context,
                      en: 'Hostel Student Wallet',
                      ar: 'محفظة الطالب السكنية',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: w >= 600 ? 28 : 24,
                          letterSpacing: -0.4,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppI18n.t(
                      context,
                      en: 'Manage Your Finances Easily',
                      ar: 'إدارة مصروفاتك بسهولة',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.72),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(flex: 2),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxCard),
                      child: PrimaryActionButton(
                        label: AppI18n.t(
                          context,
                          en: 'Get Started',
                          ar: 'ابدأ الآن',
                        ),
                        onPressed: () {
                          _autoNavigate?.cancel();
                          _goOnboarding();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
