import 'package:flutter/material.dart';

import '../models/home_finance_data.dart';
import '../services/app_i18n.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Cash / wallet illustration used on the balance card.
class WalletIllustration extends StatelessWidget {
  const WalletIllustration({super.key, this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WalletPainter()),
    );
  }
}

class _WalletPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wallet = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.28, w * 0.84, h * 0.58),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      wallet,
      Paint()..color = const Color(0xFF2FA36A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.28, w * 0.84, h * 0.18),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFF3BB56F),
    );

    final clasp = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.62, h * 0.48, w * 0.22, h * 0.18),
      const Radius.circular(8),
    );
    canvas.drawRRect(clasp, Paint()..color = const Color(0xFF1F4D3D));

    void coin(Offset c, double r, Color fill, Color rim) {
      canvas.drawCircle(c, r, Paint()..color = fill);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = rim
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    coin(Offset(w * 0.34, h * 0.22), w * 0.13, AppColors.coinGold, AppColors.coinGoldDeep);
    coin(Offset(w * 0.52, h * 0.16), w * 0.11, const Color(0xFFE8C45A), AppColors.coinGoldDeep);
    coin(Offset(w * 0.68, h * 0.24), w * 0.10, const Color(0xFFD4A017), AppColors.coinGoldDeep);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.08, w * 0.22, h * 0.16),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF4CAF7A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.totalBalance});

  final int totalBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.homePrimary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppI18n.t(context, en: 'total balance', ar: 'الرصيد الإجمالي'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatOmr(totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const WalletIllustration(size: 88),
        ],
      ),
    );
  }
}

class BillsReminder extends StatelessWidget {
  const BillsReminder({
    super.key,
    required this.bills,
    required this.onViewAll,
    this.onAddBill,
    this.now,
  });

  final List<BillItem> bills;
  final VoidCallback onViewAll;
  final VoidCallback? onAddBill;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppI18n.t(context, en: 'Bills Reminder', ar: 'تذكير الفواتير'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 118,
          height: 2,
          color: AppColors.homePrimary.withValues(alpha: 0.18),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (bills.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppI18n.t(context, en: 'No bills yet', ar: 'لا توجد فواتير بعد'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.homeMuted,
                      ),
                    ),
                  ),
                )
              else
                for (var i = 0; i < bills.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  _BillRow(bill: bills[i], now: now),
                ],
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: onAddBill,
                    child: Text(
                      AppI18n.t(context, en: 'Add bill', ar: 'إضافة فاتورة'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.homeAccent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onViewAll,
                    child: Text(
                      AppI18n.t(context, en: 'View All >', ar: 'عرض الكل >'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.homeAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.bill, this.now});

  final BillItem bill;
  final DateTime? now;

  IconData get _icon {
    switch (bill.kind) {
      case BillKind.electricity:
        return Icons.bolt_rounded;
      case BillKind.internet:
        return Icons.wifi_rounded;
      case BillKind.generic:
        return Icons.receipt_long_rounded;
    }
  }

  Color get _iconColor {
    switch (bill.kind) {
      case BillKind.electricity:
        return const Color(0xFFF5A623);
      case BillKind.internet:
        return const Color(0xFF4A90E2);
      case BillKind.generic:
        return AppColors.homeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(_icon, color: _iconColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatBillDue(bill.dueDate, now: now),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.homeMuted,
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

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: AppI18n.t(context, en: 'Home', ar: 'الرئيسية'),
                selected: currentIndex == 0,
                onTap: () => onSelected(0),
              ),
              _NavItem(
                icon: Icons.swap_horiz_rounded,
                label: AppI18n.t(context, en: 'Transactions', ar: 'المعاملات'),
                selected: currentIndex == 1,
                onTap: () => onSelected(1),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(2),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.homeAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.homeAccent.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      Text(
                        AppI18n.t(context, en: 'Add', ar: 'إضافة'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: currentIndex == 2
                              ? AppColors.homeAccent
                              : AppColors.homeNavInactive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: AppI18n.t(context, en: 'Report', ar: 'التقرير'),
                selected: currentIndex == 3,
                onTap: () => onSelected(3),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: AppI18n.t(context, en: 'Setting', ar: 'الإعدادات'),
                selected: currentIndex == 4,
                onTap: () => onSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.homeAccent : AppColors.homeNavInactive;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewCard extends StatelessWidget {
  const OverviewCard({
    super.key,
    required this.totalExpense,
    required this.totalIncome,
    required this.totalSaving,
    required this.onViewAll,
  });

  final int totalExpense;
  final int totalIncome;
  final int totalSaving;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppI18n.t(context, en: 'Overview', ar: 'نظرة عامة'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                AppI18n.t(context, en: 'View All', ar: 'عرض الكل'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.homeAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _OverviewRow(
                iconBg: AppColors.homeExpense,
                icon: Icons.remove_rounded,
                title: AppI18n.t(context, en: 'Total Expense', ar: 'إجمالي المصروف'),
                subtitle: AppI18n.t(context, en: 'This month', ar: 'هذا الشهر'),
                amount: formatOmr(
                  totalExpense,
                  sign: totalExpense == 0 ? OmrSign.none : OmrSign.minus,
                ),
                amountColor: AppColors.homeExpense,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _OverviewRow(
                iconBg: AppColors.homeIncome,
                icon: Icons.add_rounded,
                title: AppI18n.t(context, en: 'Total Income', ar: 'إجمالي الدخل'),
                subtitle: AppI18n.t(context, en: 'This month', ar: 'هذا الشهر'),
                amount: formatOmr(
                  totalIncome,
                  sign: totalIncome == 0 ? OmrSign.none : OmrSign.plus,
                ),
                amountColor: AppColors.homeIncome,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _OverviewRow(
                iconBg: AppColors.homeSaving,
                icon: Icons.savings_rounded,
                title: AppI18n.t(context, en: 'Total Saving', ar: 'إجمالي الادخار'),
                subtitle: AppI18n.t(context, en: 'This month', ar: 'هذا الشهر'),
                amount: formatOmr(
                  totalSaving,
                  sign: totalSaving == 0 ? OmrSign.none : OmrSign.plus,
                ),
                amountColor: AppColors.homeSaving,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
  });

  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.homeMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onAddSaving,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onAddSaving;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppI18n.t(context, en: 'Quick Actions', ar: 'إجراءات سريعة'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Expanded(
              child: _QuickActionCard(
                color: AppColors.homeExpense,
                icon: Icons.remove_rounded,
                title: AppI18n.t(context, en: 'Add Expense', ar: 'إضافة مصروف'),
                subtitle: AppI18n.t(context, en: 'Track Spending', ar: 'تتبع الإنفاق'),
                onTap: onAddExpense,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                color: AppColors.homeIncome,
                icon: Icons.add_rounded,
                title: AppI18n.t(context, en: 'Add Income', ar: 'إضافة دخل'),
                subtitle: AppI18n.t(context, en: 'Recent Income', ar: 'دخل حديث'),
                onTap: onAddIncome,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                color: const Color(0xFF3A3A3A),
                icon: Icons.savings_rounded,
                title: AppI18n.t(context, en: 'Add Saving', ar: 'إضافة ادخار'),
                subtitle: AppI18n.t(context, en: 'Save for future', ar: 'ادخر للمستقبل'),
                onTap: onAddSaving,
              ),
            ),
          ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.homeMuted,
                    height: 1.2,
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

extension QuickActionsKind on TransactionKind {
  String get addTitle {
    switch (this) {
      case TransactionKind.expense:
        return 'Add Expense';
      case TransactionKind.income:
        return 'Add Income';
      case TransactionKind.saving:
        return 'Add Saving';
    }
  }

  String localizedAddTitle(BuildContext context) {
    switch (this) {
      case TransactionKind.expense:
        return AppI18n.t(context, en: 'Add Expense', ar: 'إضافة مصروف');
      case TransactionKind.income:
        return AppI18n.t(context, en: 'Add Income', ar: 'إضافة دخل');
      case TransactionKind.saving:
        return AppI18n.t(context, en: 'Add Saving', ar: 'إضافة ادخار');
    }
  }
}
