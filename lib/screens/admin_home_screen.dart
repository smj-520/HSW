import 'package:flutter/material.dart';
import '../constants/admin_home.dart';
import '../services/app_i18n.dart';
import '../services/admin_services.dart';
import '../widgets/admin_card.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/blocked_account_guard.dart';
import './admin_report_screen.dart';
import './biller_screen.dart';
import './feedback_screen.dart';
import './user_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _authService = AdminAuthService();
  final _userService = AdminUserService();
  final _billerService = BillerService();
  final _feedbackService = FeedbackService();
  bool isLoading = false;
  int currentIndex = 0;
  int? studentCount;
  int? billerCount;
  int? newFeedbackCount;

  Future<void> logOut() async {
    setState(() => isLoading = true);
    await _authService.logOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void onTabTap(int index) {
    setState(() => currentIndex = index);
    if (index == 0) {
      loadHomeCounts();
    }
  }

  void openPage(int index) {
    setState(() => currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    loadHomeCounts();
  }

  Future<void> loadHomeCounts() async {
    try {
      final users = await _userService.loadUserList();
      final billers = await _billerService.loadBillerList();
      final feedback = await _feedbackService.loadFeedbackList();
      if (!mounted) return;
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      setState(() {
        studentCount = users.where((user) => !user.isAdmin).length;
        billerCount = billers.length;
        newFeedbackCount =
            feedback.where((item) => item.createdAt.isAfter(weekAgo)).length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        studentCount = null;
        billerCount = null;
        newFeedbackCount = null;
      });
    }
  }

  Widget homePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 600;
        final maxDash = twoCols ? 680.0 : 440.0;
        final pad = twoCols ? 28.0 : 20.0;
        final scheme = Theme.of(context).colorScheme;
        return ListView(
          padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxDash),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppI18n.t(
                        context,
                        en: 'Welcome, Admin',
                        ar: 'مرحباً، المسؤول',
                      ),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppI18n.t(
                        context,
                        en: 'Manage the application easily',
                        ar: 'أدِر التطبيق بسهولة',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: twoCols ? 2 : 1,
                      mainAxisSpacing: twoCols ? 16 : 12,
                      crossAxisSpacing: twoCols ? 16 : 12,
                      childAspectRatio: twoCols ? 1.12 : 2.35,
                      children: [
                        AdminCard(
                          color: AdminHomeColors.user,
                          glyphKey: 'user',
                          title: AppI18n.t(
                            context,
                            en: 'Manage User',
                            ar: 'إدارة المستخدمين',
                          ),
                          subtitle: AppI18n.t(
                            context,
                            en: 'Students in the hostel',
                            ar: 'الطلاب في السكن',
                          ),
                          badge: studentCount == null
                              ? null
                              : AppI18n.t(
                                  context,
                                  en: '$studentCount students',
                                  ar: '$studentCount طالب',
                                ),
                          onTap: () => openPage(1),
                        ),
                        AdminCard(
                          color: AdminHomeColors.biller,
                          glyphKey: 'biller',
                          title: AppI18n.t(
                            context,
                            en: 'Manage Biller',
                            ar: 'إدارة الجهات',
                          ),
                          subtitle: AppI18n.t(
                            context,
                            en: 'Payment recipients',
                            ar: 'جهات الدفع',
                          ),
                          badge: billerCount == null
                              ? null
                              : AppI18n.t(
                                  context,
                                  en: '$billerCount billers',
                                  ar: '$billerCount جهات',
                                ),
                          onTap: () => openPage(2),
                        ),
                        AdminCard(
                          color: AdminHomeColors.report,
                          glyphKey: 'report',
                          title: AppI18n.t(
                            context,
                            en: 'View Report',
                            ar: 'عرض التقرير',
                          ),
                          subtitle: AppI18n.t(
                            context,
                            en: 'Payments overview',
                            ar: 'نظرة على المدفوعات',
                          ),
                          badge: AppI18n.t(
                            context,
                            en: 'This month',
                            ar: 'هذا الشهر',
                          ),
                          onTap: () => openPage(3),
                        ),
                        AdminCard(
                          color: AdminHomeColors.feedback,
                          glyphKey: 'feedback',
                          title: AppI18n.t(
                            context,
                            en: 'View Feedback',
                            ar: 'عرض الملاحظات',
                          ),
                          subtitle: AppI18n.t(
                            context,
                            en: 'Messages from students',
                            ar: 'رسائل الطلاب',
                          ),
                          badge: (newFeedbackCount == null ||
                                  newFeedbackCount == 0)
                              ? null
                              : AppI18n.t(
                                  context,
                                  en: '$newFeedbackCount new',
                                  ar: '$newFeedbackCount جديدة',
                                ),
                          onTap: () => openPage(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      homePage(),
      const UserScreen(),
      const BillerScreen(),
      const AdminReportScreen(),
      const FeedbackScreen(),
    ];
    final scheme = Theme.of(context).colorScheme;

    final logoutLabel = AppI18n.t(context, en: 'Log Out', ar: 'تسجيل الخروج');
    Widget logoutChip({required bool visible}) {
      final chip = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: _AdminLogoutButton(
          label: logoutLabel,
          onPressed: isLoading ? null : logOut,
        ),
      );
      if (visible) return chip;
      return IgnorePointer(child: Opacity(opacity: 0, child: chip));
    }

    return BlockedAccountGuard(
      child: Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        centerTitle: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        leadingWidth: 148,
        leading: logoutChip(visible: false),
        title: Text(
          AppI18n.t(context, en: 'Admin', ar: 'المسؤول'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [logoutChip(visible: true)],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : pages[currentIndex],
      ),
      bottomNavigationBar: AppBottomNav.admin(
        context: context,
        currentIndex: currentIndex,
        onSelected: onTabTap,
      ),
    ),
    );
  }
}

class _AdminLogoutButton extends StatefulWidget {
  const _AdminLogoutButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_AdminLogoutButton> createState() => _AdminLogoutButtonState();
}

class _AdminLogoutButtonState extends State<_AdminLogoutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: widget.onPressed == null ? 0.55 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 108),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE15A5A),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE15A5A).withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
