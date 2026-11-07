import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_i18n.dart';
import '../theme/app_colors.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/hostel_brand.dart';
import '../widgets/responsive_layout.dart';

/// About screen opened from Settings. Same route, new layout..
class AboutApplicationPage extends StatefulWidget {
  const AboutApplicationPage({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  State<AboutApplicationPage> createState() => _AboutApplicationPageState();
}

class _AboutApplicationPageState extends State<AboutApplicationPage> {
  static const _supportEmail = 'support@hostelwallet.app';

  Future<void> _openSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('Hostel Student Wallet support')}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(
              context,
              en: 'Could not open the email app. Please write to $_supportEmail',
              ar: 'تعذر فتح تطبيق البريد. يرجى الكتابة إلى $_supportEmail',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = scheme.surface;
    final topPad = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: pageBg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: 292 + topPad * 0.15,
              backgroundColor: AppColors.homePrimary,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Text(
                context.tr('About application', 'حول التطبيق'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: Colors.white,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: const _HeroBackdrop(),
              ),
            ),
            SliverToBoxAdapter(
              child: ResponsiveContent(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedAppear(
                          index: 0,
                          child: Text(
                            AppI18n.t(
                              context,
                              en: 'About Hostel Student Wallet',
                              ar: 'حول محفظة الطالب السكنية',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              height: 1.2,
                              color: isDark
                                  ? scheme.onSurface
                                  : AppColors.homePrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedAppear(
                          index: 1,
                          child: _SoftCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AccentBar(),
                                const SizedBox(height: 12),
                                Text(
                                  AppI18n.t(
                                    context,
                                    en:
                                        'The Hostel Student Wallet enables hostel students to manage their finances more effectively through a mobile application, which gives students the ability to track their daily income and expenses, and savings; set budget limits; and get reminders of important payments (such as hostel fees and utility bills). In addition, students using the application receive access to reports that will help them better understand where their money goes and help them manage their finances more effectively.',
                                    ar:
                                        'يمكّن تطبيق محفظة الطالب السكنية طلاب السكن من إدارة أموالهم بشكل أكثر فعالية من خلال تطبيق جوال يتيح للطلاب تتبع الدخل والمصروفات اليومية والمدخرات، وتحديد حدود الميزانية، والحصول على تذكيرات بالمدفوعات المهمة (مثل رسوم السكن وفواتير الخدمات). كما يحصل الطلاب الذين يستخدمون التطبيق على تقارير تساعدهم على فهم أين تذهب أموالهم وإدارة شؤونهم المالية بشكل أفضل.',
                                  ),
                                  style: _bodyStyle(context, isDark),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  AppI18n.t(
                                    context,
                                    en:
                                        'This project also supports Oman’s Vision 2040 by creating opportunities for young Omanis to become more digitally savvy and thereby increasing their overall level of financial literacy.',
                                    ar:
                                        'ويدعم هذا المشروع رؤية عُمان 2040 من خلال توفير فرص للشباب العُماني ليصبحوا أكثر مهارة رقمياً، وبذلك يرتفع مستوى الثقافة المالية لديهم بشكل عام.',
                                  ),
                                  style: _bodyStyle(context, isDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        AnimatedAppear(
                          index: 2,
                          child: Text(
                            AppI18n.t(
                              context,
                              en: 'Key features',
                              ar: 'الميزات الرئيسية',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: isDark
                                  ? scheme.onSurface
                                  : AppColors.homePrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FeatureGrid(isDark: isDark),
                        const SizedBox(height: 22),
                        AnimatedAppear(
                          index: 8,
                          child: const _Vision2040Card(),
                        ),
                        if (widget.isAdmin) ...[
                          const SizedBox(height: 14),
                          AnimatedAppear(
                            index: 9,
                            child: _AdminNoteCard(isDark: isDark),
                          ),
                        ],
                        const SizedBox(height: 14),
                        AnimatedAppear(
                          index: 10,
                          child: _ContactCard(
                            isDark: isDark,
                            onEmailTap: _openSupportEmail,
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _bodyStyle(BuildContext context, bool isDark) {
    return TextStyle(
      height: 1.58,
      fontSize: 15,
      color: isDark
          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88)
          : const Color(0xFF33413A),
    );
  }
}

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/branding/about_hero.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.15),
          filterQuality: FilterQuality.high,
          semanticLabel: AppI18n.t(
            context,
            en:
                'University students managing money, savings, and student life',
            ar: 'طلاب جامعيون يديرون أموالهم ومدخراتهم وحياتهم الطلابية',
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x661F4D3D),
                Color(0x001F4D3D),
                Color(0xE61F4D3D),
              ],
              stops: [0, 0.38, 1],
            ),
          ),
        ),
        PositionedDirectional(
          start: 20,
          end: 20,
          bottom: 22,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const HostelWalletGlyph(size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppI18n.t(
                        context,
                        en: 'Hostel Student Wallet',
                        ar: 'محفظة الطالب السكنية',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        AppI18n.t(
                          context,
                          en: 'Version 1.0.0',
                          ar: 'نسخة 1.0.0',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccentBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [AppColors.homeIncome, AppColors.homePrimary],
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final items = <_FeatureData>[
      _FeatureData(
        icon: Icons.swap_vert_rounded,
        titleEn: 'Income & Expense Tracking',
        titleAr: 'تتبع الدخل والمصروفات',
        bodyEn: 'Track daily transactions easily.',
        bodyAr: 'تتبع المعاملات اليومية بسهولة.',
        tint: AppColors.homeIncome,
      ),
      _FeatureData(
        icon: Icons.pie_chart_rounded,
        titleEn: 'Budget Management',
        titleAr: 'إدارة الميزانية',
        bodyEn: 'Set budget limits and manage spending.',
        bodyAr: 'حدد حدود الميزانية وأدر إنفاقك.',
        tint: AppColors.homeAccent,
      ),
      _FeatureData(
        icon: Icons.savings_rounded,
        titleEn: 'Savings Tracking',
        titleAr: 'تتبع الادخار',
        bodyEn: 'Monitor savings and financial goals.',
        bodyAr: 'راقب المدخرات والأهداف المالية.',
        tint: AppColors.homeSaving,
      ),
      _FeatureData(
        icon: Icons.notifications_active_rounded,
        titleEn: 'Payment Reminders',
        titleAr: 'تذكيرات المدفوعات',
        bodyEn: 'Never miss hostel fees or utility bill payments.',
        bodyAr: 'لا تفوّت رسوم السكن أو فواتير الخدمات.',
        tint: const Color(0xFFC0392B),
      ),
      _FeatureData(
        icon: Icons.insights_rounded,
        titleEn: 'Financial Reports',
        titleAr: 'التقارير المالية',
        bodyEn: 'Understand spending habits through clear reports.',
        bodyAr: 'افهم عادات الإنفاق من خلال تقارير واضحة.',
        tint: AppColors.homePrimary,
        wide: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 10.0;
        final half = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: items[i].wide ? constraints.maxWidth : half,
                child: AnimatedAppear(
                  index: 3 + i,
                  child: _FeatureCard(data: items[i], isDark: isDark),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.tint,
    this.wide = false,
  });

  final IconData icon;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final Color tint;
  final bool wide;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data, required this.isDark});

  final _FeatureData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final title = AppI18n.t(context, en: data.titleEn, ar: data.titleAr);
    final body = AppI18n.t(context, en: data.bodyEn, ar: data.bodyAr);

    final icon = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: data.tint.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(data.icon, color: data.tint, size: 24),
    );

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            height: 1.25,
            color: isDark
                ? Theme.of(context).colorScheme.onSurface
                : AppColors.homePrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: TextStyle(
            fontSize: 12.8,
            height: 1.4,
            color: isDark
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                : AppColors.homeMuted,
          ),
        ),
      ],
    );

    return _SoftCard(
      padding: const EdgeInsets.all(14),
      child: data.wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: texts),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(height: 12),
                texts,
              ],
            ),
    );
  }
}

class _Vision2040Card extends StatelessWidget {
  const _Vision2040Card();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16382C), Color(0xFF1F4D3D), Color(0xFF2E7D5B)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.homePrimary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PositionedDirectional(
            end: -24,
            bottom: -28,
            child: Icon(
              Icons.account_balance_rounded,
              size: 128,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _OmanMotif(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppI18n.t(
                          context,
                          en: 'Supporting Oman Vision 2040',
                          ar: 'دعم رؤية عُمان 2040',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppI18n.t(
                    context,
                    en:
                        'Hostel Student Wallet supports Oman Vision 2040 by helping young Omanis build digital skills, grow financial awareness, and raise their overall financial literacy through everyday money management on a mobile app.',
                    ar:
                        'يدعم تطبيق محفظة الطالب السكنية رؤية عُمان 2040 بمساعدة الشباب العُماني على بناء المهارات الرقمية، وزيادة الوعي المالي، ورفع مستوى الثقافة المالية من خلال إدارة الأموال اليومية عبر تطبيق جوال.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OmanMotif extends StatelessWidget {
  const _OmanMotif();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 42,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(width: 11, color: const Color(0xFFC8102E)),
            const Expanded(
              child: Column(
                children: [
                  Expanded(child: ColoredBox(color: Colors.white)),
                  Expanded(child: ColoredBox(color: Color(0xFFC8102E))),
                  Expanded(child: ColoredBox(color: Color(0xFF00843D))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNoteCard extends StatelessWidget {
  const _AdminNoteCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.homeAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Administration panel', 'لوحة الإدارة'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? Theme.of(context).colorScheme.onSurface
                        : AppColors.homePrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppI18n.t(
                    context,
                    en:
                        'This account has elevated permissions for user and settings administration.',
                    ar:
                        'هذه النسخة تتضمن صلاحيات إدارة المستخدمين والإعدادات.',
                  ),
                  style: TextStyle(
                    height: 1.4,
                    color: isDark
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7)
                        : AppColors.homeMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.isDark,
    required this.onEmailTap,
  });

  final bool isDark;
  final VoidCallback onEmailTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62)
        : AppColors.homeMuted;
    final valueColor = isDark
        ? Theme.of(context).colorScheme.onSurface
        : AppColors.homePrimary;

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppI18n.t(
              context,
              en: 'Contact and app information',
              ar: 'التواصل ومعلومات التطبيق',
            ),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(
            Icons.account_balance_wallet_outlined,
            AppI18n.t(context, en: 'App name', ar: 'اسم التطبيق'),
            AppI18n.t(
              context,
              en: 'Hostel Student Wallet',
              ar: 'محفظة الطالب السكنية',
            ),
            labelColor,
            valueColor,
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.verified_outlined,
            AppI18n.t(context, en: 'Version', ar: 'الإصدار'),
            '1.0.0',
            labelColor,
            valueColor,
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.homeAccent.withValues(alpha: isDark ? 0.16 : 0.1),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onEmailTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 22,
                      color: AppColors.homeAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppI18n.t(
                              context,
                              en: 'Support email',
                              ar: 'بريد الدعم',
                            ),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'support@hostelwallet.app',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.homeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: AppColors.homeAccent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.homeAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.homePrimary.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
