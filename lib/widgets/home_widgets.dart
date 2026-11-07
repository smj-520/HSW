import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../constants/categories.dart';
import '../models/home_finance_data.dart';
import '../services/app_i18n.dart';
import '../theme/app_colors.dart';
import '../utils/app_messages.dart';
import '../utils/formatters.dart';
import '../utils/wallet_tc_logic.dart';
import 'category_icon.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A32),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppI18n.t(context, en: 'Total balance', ar: 'الرصيد الإجمالي'),
                  style: const TextStyle(
                    color: Color(0xFF9FD3B2),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatOmr(totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF70),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(6),
            child: const WalletIllustration(size: 40),
          ),
        ],
      ),
    );
  }
}

class OverviewStrip extends StatelessWidget {
  const OverviewStrip({
    super.key,
    required this.expense,
    required this.income,
    required this.saving,
  });

  final int expense;
  final int income;
  final int saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _cell(
            context,
            AppI18n.t(context, en: 'Expense', ar: 'المصروف'),
            formatOmr(expense),
            const Color(0xFFE24B4A),
          ),
          Container(
            width: 1,
            height: 36,
            color: Theme.of(context).dividerColor,
          ),
          _cell(
            context,
            AppI18n.t(context, en: 'Income', ar: 'الدخل'),
            formatOmr(income),
            const Color(0xFF2E9E5B),
          ),
          Container(
            width: 1,
            height: 36,
            color: Theme.of(context).dividerColor,
          ),
          _cell(
            context,
            AppI18n.t(context, en: 'Saving', ar: 'الادخار'),
            formatOmr(saving),
            const Color(0xFFE0A100),
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, String label, String amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
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
    this.onBillTap,
    this.now,
  });

  final List<BillItem> bills;
  final VoidCallback onViewAll;
  final VoidCallback? onAddBill;
  final ValueChanged<BillItem>? onBillTap;
  final DateTime? now;

  List<BillItem> get _upcoming {
    final unpaid = [for (final b in bills) if (b.isUnpaid) b]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return unpaid.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _upcoming;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppI18n.t(context, en: 'Bills Reminder', ar: 'تذكير الفواتير'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                AppI18n.t(context, en: 'View All >', ar: 'عرض الكل'),
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
        if (rows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  AppI18n.t(context, en: 'No bills yet', ar: 'لا توجد فواتير بعد'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onAddBill,
                  child: Text(
                    AppI18n.t(context, en: 'Add bill', ar: 'إضافة فاتورة'),
                  ),
                ),
              ],
            ),
          )
        else
          for (final bill in rows) ...[
            _BillReminderCard(
              bill: bill,
              now: now,
              onTap: () => onBillTap?.call(bill),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _BillReminderCard extends StatelessWidget {
  const _BillReminderCard({
    required this.bill,
    required this.onTap,
    this.now,
  });

  final BillItem bill;
  final VoidCallback onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final cat = expenseCategoryById(
      normalizeExpenseCategoryId(bill.category ?? bill.name),
    ) ??
        kExpenseCategories.last;
    final pill = billDuePill(bill.dueDate, now: now);
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              CategoryIcon(cat.id, cat.color, 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatOmr(bill.amountBaisa),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('d MMM yyyy').format(bill.dueDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pill.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pill.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pill.color,
                  ),
                ),
              ),
            ],
          ),
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
    this.expenseSlices = const [],
  });

  final int totalExpense;
  final int totalIncome;
  final int totalSaving;
  final VoidCallback onViewAll;
  final List<ExpenseSlice> expenseSlices;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppI18n.t(context, en: 'Overview', ar: 'نظرة عامة'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
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
        _HomeExpensePie(slices: expenseSlices),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).cardColor,
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _HomeExpensePie extends StatelessWidget {
  const _HomeExpensePie({required this.slices});

  final List<ExpenseSlice> slices;

  static const _palette = [
    AppColors.homeExpense,
    AppColors.homeIncome,
    AppColors.homeSaving,
    AppColors.homeAccent,
    Color(0xFF42A5F5),
    Color(0xFF7E57C2),
    Color(0xFFFF8A65),
  ];

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            AppMessages.noChartData,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 36,
          sections: [
            for (var i = 0; i < slices.length; i++)
              PieChartSectionData(
                value: slices[i].amountBaisa.toDouble(),
                title: '${slices[i].percent}%',
                color: _palette[i % _palette.length],
                radius: 48,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
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
