import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_i18n.dart';
import '../theme/app_colors.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../models/report_model.dart';

/// Shared cream + card look for Summary and Report (styling only).
abstract final class FinanceSurface {
  static const Color pageBg = Color(0xFFF9F6F0);
  static const Color ink = Color(0xFF1F4D3D);
  static const Color muted = Color(0xFF8A8F8A);
  static const Color pillIdle = Color(0xFFE8E6E1);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.homePrimary.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static BoxDecoration card({double radius = 22}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: cardShadow,
    );
  }
}

class WeekMonthPills extends StatelessWidget {
  const WeekMonthPills({
    super.key,
    required this.showWeekly,
    required this.onWeekly,
    required this.onMonthly,
  });

  final bool showWeekly;
  final VoidCallback onWeekly;
  final VoidCallback onMonthly;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill(
          label: AppI18n.t(context, en: 'Weekly', ar: 'أسبوعي'),
          selected: showWeekly,
          onTap: onWeekly,
        ),
        const SizedBox(width: 12),
        _pill(
          label: AppI18n.t(context, en: 'Monthly', ar: 'شهري'),
          selected: !showWeekly,
          onTap: onMonthly,
        ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : FinanceSurface.pillIdle,
            borderRadius: BorderRadius.circular(28),
            boxShadow: selected ? FinanceSurface.cardShadow : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: selected ? AppColors.homeIncome : FinanceSurface.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class FinancePrimaryButton extends StatelessWidget {
  const FinancePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final button = SizedBox(
      width: expand ? double.infinity : (w >= 700 ? 280.0 : 200.0),
      height: w >= 700 ? 58 : 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.homeIncome,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.homeIncome.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.homeIncome.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: button,
    );
  }
}

class FinancePageTitle extends StatelessWidget {
  const FinancePageTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: FinanceSurface.ink,
      ),
    );
  }
}

// Week or month label with left/right arrows. Next is disabled in the future.
class PeriodSwitcher extends StatelessWidget {
  const PeriodSwitcher({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Container(
        decoration: FinanceSurface.card(radius: 18),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
              color: FinanceSurface.ink,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: FinanceSurface.ink,
                ),
              ),
            ),
            IconButton(
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
              color: FinanceSurface.ink,
            ),
          ],
        ),
      ),
    );
  }
}

// Turns a week start/end into text like "21 Apr – 27 Apr 2026".
String weekPeriodLabel(DateTime startDate, DateTime endDate) {
  final start = DateFormat('d MMM').format(startDate);
  final end = DateFormat('d MMM yyyy').format(endDate);
  return '$start – $end';
}

// Turns a month into text like "May 2026".
String monthPeriodLabel(DateTime day) {
  return DateFormat('MMMM yyyy').format(day);
}

const _barColors = [
  Color(0xFFE74C3C),
  Color(0xFFF1C40F),
  Color(0xFF3498DB),
  Color(0xFF27AE60),
  Color(0xFF9B59B6),
  Color(0xFFE67E22),
];

// Bar chart of expenses by category, with percentages from the report.
class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key, required this.categoryTotals});

  final List<CategoryTotal> categoryTotals;

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No data for this period yet',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    var maxAmount = 1;
    for (final item in categoryTotals) {
      if (item.amountBaisa > maxAmount) maxAmount = item.amountBaisa;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 168,
          width: 168,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAmount.toDouble() * 1.15,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(width: 2.2, color: FinanceSurface.ink.withValues(alpha: 0.85)),
                  bottom: BorderSide(width: 2.2, color: FinanceSurface.ink.withValues(alpha: 0.85)),
                ),
              ),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: [
                for (var i = 0; i < categoryTotals.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: categoryTotals[i].amountBaisa.toDouble(),
                        color: _barColors[i % _barColors.length],
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < categoryTotals.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsetsDirectional.only(end: 8),
                        decoration: BoxDecoration(
                          color: _barColors[i % _barColors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          categoryTotals[i].name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: FinanceSurface.ink,
                          ),
                        ),
                      ),
                      Text(
                        '${(categoryTotals[i].percent * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: FinanceSurface.ink,
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

// One report line: date, title, type, amount.
class ReportTransactionRow extends StatelessWidget {
  const ReportTransactionRow({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final Color amountColor;
    final OmrSign sign;
    final String typeLabel;
    final IconData icon;
    final Color iconBg;
    if (transaction.isIncome) {
      amountColor = const Color(0xFF27AE60);
      sign = OmrSign.plus;
      typeLabel = 'Income';
      icon = Icons.south_west_rounded;
      iconBg = const Color(0xFFE6F6EC);
    } else if (transaction.isSaving) {
      amountColor = const Color(0xFFD4A017);
      sign = OmrSign.plus;
      typeLabel = 'Saving';
      icon = Icons.savings_outlined;
      iconBg = const Color(0xFFFFF4D6);
    } else {
      amountColor = const Color(0xFFE74C3C);
      sign = OmrSign.minus;
      typeLabel = 'Expense';
      icon = Icons.north_east_rounded;
      iconBg = const Color(0xFFFDECEA);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: amountColor, size: 20),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              DateFormat('d MMM').format(transaction.date.toLocal()),
              style: const TextStyle(
                color: FinanceSurface.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: FinanceSurface.ink,
                  ),
                ),
                Text(
                  typeLabel,
                  style: const TextStyle(color: FinanceSurface.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatOmr(transaction.amountBaisa, sign: sign),
            style: TextStyle(color: amountColor, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
