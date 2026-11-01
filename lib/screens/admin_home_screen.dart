import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../services/admin_services.dart';
import '../widgets/admin_widgets.dart';
import './admin_report_screen.dart';
import './biller_screen.dart';
import './feedback_screen.dart';
import './user_screen.dart';

// This is the first page an admin sees after login.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _authService = AdminAuthService();
  bool isLoading = false;
  int currentIndex = 0;

  // Signs out, then opens Login and deletes every page behind it.
  Future<void> logOut() async {
    setState(() => isLoading = true);
    await _authService.logOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // Changes the tab when the admin taps the bottom bar.
  void onTabTap(int index) {
    setState(() => currentIndex = index);
  }

  // Opens a tab from one of the four home cards.
  void openPage(int index) {
    setState(() => currentIndex = index);
  }

  // The welcome text plus the 2x2 grid of cards.
  Widget homePage() {
    return ResponsiveContent(
      child: Padding(
      padding: EdgeInsets.all(responsivePagePaddingX(MediaQuery.sizeOf(context).width).clamp(16, 28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppI18n.t(context, en: 'Welcome, Admin 👋', ar: 'مرحباً، المسؤول 👋'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppI18n.t(
              context,
              en: 'Manage the application easily',
              ar: 'أدر التطبيق بسهولة',
            ),
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                AdminCard(
                  icon: Icons.account_circle_outlined,
                  label: AppI18n.t(context, en: 'Manage User', ar: 'إدارة المستخدمين'),
                  onTap: () => openPage(1),
                ),
                AdminCard(
                  icon: Icons.receipt_long_outlined,
                  label: AppI18n.t(context, en: 'Manage Biller', ar: 'إدارة الجهات'),
                  onTap: () => openPage(2),
                ),
                AdminCard(
                  icon: Icons.pie_chart_outline,
                  label: AppI18n.t(context, en: 'View Report', ar: 'عرض التقرير'),
                  onTap: () => openPage(3),
                ),
                AdminCard(
                  icon: Icons.rate_review_outlined,
                  label: AppI18n.t(context, en: 'View Feedback', ar: 'عرض الملاحظات'),
                  onTap: () => openPage(4),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F0),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(AppI18n.t(context, en: 'Admin', ar: 'المسؤول')),
        actions: [
          TextButton(
            onPressed: isLoading ? null : logOut,
            child: Text(
              AppI18n.t(context, en: 'Log Out', ar: 'تسجيل الخروج'),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : pages[currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppI18n.t(context, en: 'Home', ar: 'الرئيسية'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: AppI18n.t(context, en: 'User', ar: 'المستخدم'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            label: AppI18n.t(context, en: 'Biller', ar: 'الجهة'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pie_chart_outline),
            label: AppI18n.t(context, en: 'Report', ar: 'التقرير'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.rate_review_outlined),
            label: AppI18n.t(context, en: 'Feedback', ar: 'الملاحظات'),
          ),
        ],
      ),
    );
  }
}
