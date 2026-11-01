import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/home_finance_data.dart';
import '../services/app_i18n.dart';
import '../theme/app_colors.dart';
import '../widgets/home_widgets.dart';
import '../widgets/responsive_layout.dart';

/// Finance overview home. First name and totals come from [firstName] / [data].
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.firstName,
    required this.data,
    this.now,
    this.onNotificationTap,
    this.onAddExpense,
    this.onAddIncome,
    this.onAddSaving,
    this.onViewAllOverview,
    this.onViewAllBills,
    this.onAddBill,
    this.onOpenBudget,
  });

  final String firstName;
  final HomeFinanceData data;
  final DateTime? now;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddIncome;
  final VoidCallback? onAddSaving;
  final VoidCallback? onViewAllOverview;
  final VoidCallback? onViewAllBills;
  final VoidCallback? onAddBill;
  final VoidCallback? onOpenBudget;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ColoredBox(
        color: AppColors.homeBackground,
        child: SafeArea(
          bottom: false,
          child: ResponsiveContent(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  responsivePagePaddingX(MediaQuery.sizeOf(context).width),
                  8,
                  responsivePagePaddingX(MediaQuery.sizeOf(context).width),
                  40,
                ),
                children: [
                  _HomeHeader(
                    firstName: firstName,
                    onNotificationTap: onNotificationTap,
                    hasAlerts: data.bills.isNotEmpty,
                  ),
                  const SizedBox(height: 16),
                  BalanceCard(totalBalance: data.totalBalance),
                  const SizedBox(height: 24),
                  QuickActions(
                    onAddExpense: onAddExpense ?? () {},
                    onAddIncome: onAddIncome ?? () {},
                    onAddSaving: onAddSaving ?? () {},
                  ),
                  const SizedBox(height: 24),
                  OverviewCard(
                    totalExpense: data.totalExpense,
                    totalIncome: data.totalIncome,
                    totalSaving: data.totalSaving,
                    onViewAll: onViewAllOverview ?? () {},
                  ),
                  const SizedBox(height: 24),
                  BillsReminder(
                    bills: data.bills,
                    now: now,
                    onViewAll: onViewAllBills ?? () {},
                    onAddBill: onAddBill,
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: _BudgetButton(onPressed: onOpenBudget),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}

class _BudgetButton extends StatelessWidget {
  const _BudgetButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = AppI18n.t(context, en: 'Budget', ar: 'الميزانية');
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.homeAccent.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            width: (MediaQuery.sizeOf(context).width * 0.42).clamp(228.0, 360.0),
            height: 54,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF1F4D3D),
                  Color(0xFF27AE60),
                  Color(0xFF2E7D5B),
                ],
              ),
            ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.2,
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.firstName,
    required this.hasAlerts,
    this.onNotificationTap,
  });

  final String firstName;
  final bool hasAlerts;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppI18n.t(context, en: 'Hi, $firstName', ar: 'مرحباً، $firstName'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppI18n.t(
                  context,
                  en: "Here's your financial overview",
                  ar: 'هذه نظرة عامة على وضعك المالي',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.homeMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: AppI18n.t(context, en: 'Notifications', ar: 'الإشعارات'),
          onPressed: onNotificationTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textPrimary,
                size: 26,
              ),
              if (hasAlerts)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.homeExpense,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
