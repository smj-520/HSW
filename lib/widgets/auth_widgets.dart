import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../theme/app_colors.dart';

class AuthFormFooterBranding extends StatelessWidget {
  const AuthFormFooterBranding({
    super.key,
    required this.title,
    required this.subtitle,
    required this.logoHeight,
  });

  final String title;
  final String subtitle;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: logoHeight,
          child: ClipRect(
            child: Transform.scale(
              scale: 1.12,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/branding/splash_wallet_hero.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
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
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: w >= 600 ? 20 : 17.5,
            letterSpacing: -0.3,
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12.5,
            color: scheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class AuthFormFrame extends StatelessWidget {
  const AuthFormFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? scheme.outline.withValues(alpha: 0.45)
              : const Color(0xFFADDCC0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class RoundedBackButton extends StatelessWidget {
  const RoundedBackButton({super.key, this.onPressed, this.tooltip});

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
      child: Material(
        color: scheme.surfaceContainerHigh,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed ?? () => Navigator.maybePop(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
