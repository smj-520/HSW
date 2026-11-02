import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_i18n.dart';
import '../theme/app_colors.dart';
import '../theme/app_surfaces.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../models/report_model.dart';
import 'category_icon.dart';

/// Shared page + card look for Summary and Report (styling only).
abstract final class FinanceSurface {
  static Color pageBg(BuildContext context) => AppSurfaces.page(context);
  static Color ink(BuildContext context) => AppSurfaces.ink(context);
  static Color muted(BuildContext context) => AppSurfaces.muted(context);
  static Color pillIdle(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static List<BoxShadow> cardShadow(BuildContext context) =>
      AppSurfaces.cardShadow(context);

  static BoxDecoration card(BuildContext context, {double radius = 22}) {
    return BoxDecoration(
      color: AppSurfaces.card(context),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: cardShadow(context),
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
          context: context,
          label: AppI18n.t(context, en: 'Weekly', ar: 'أسبوعي'),
          selected: showWeekly,
          onTap: onWeekly,
        ),
        const SizedBox(width: 12),
        _pill(
          context: context,
          label: AppI18n.t(context, en: 'Monthly', ar: 'شهري'),
          selected: !showWeekly,
          onTap: onMonthly,
        ),
      ],
    );
  }

  Widget _pill({
    required BuildContext context,
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
            color: selected
                ? Theme.of(context).cardColor
                : FinanceSurface.pillIdle(context),
            borderRadius: BorderRadius.circular(28),
            boxShadow: selected ? FinanceSurface.cardShadow(context) : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: selected ? AppColors.homeIncome : FinanceSurface.muted(context),
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
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: FinanceSurface.ink(context),
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
        decoration: FinanceSurface.card(context, radius: 18),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
              color: FinanceSurface.ink(context),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: FinanceSurface.ink(context),
                ),
              ),
            ),
            IconButton(
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
              color: FinanceSurface.ink(context),
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
                  left: BorderSide(width: 2.2, color: FinanceSurface.ink(context).withValues(alpha: 0.85)),
                  bottom: BorderSide(width: 2.2, color: FinanceSurface.ink(context).withValues(alpha: 0.85)),
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
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: CategoryIcon(
                          categoryTotals[i].id,
                          categoryTileColor(categoryTotals[i].id),
                          22,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          categoryTotals[i].name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: FinanceSurface.ink(context),
                          ),
                        ),
                      ),
                      Text(
                        '${(categoryTotals[i].percent * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: FinanceSurface.ink(context),
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
    final IconData? typeIcon;
    final Color iconBg;
    if (transaction.isIncome) {
      amountColor = const Color(0xFF27AE60);
      sign = OmrSign.plus;
      typeLabel = 'Income';
      typeIcon = Icons.south_west_rounded;
      iconBg = const Color(0xFFE6F6EC);
    } else if (transaction.isSaving) {
      amountColor = const Color(0xFFD4A017);
      sign = OmrSign.plus;
      typeLabel = 'Saving';
      typeIcon = Icons.savings_outlined;
      iconBg = const Color(0xFFFFF4D6);
    } else {
      amountColor = const Color(0xFFE74C3C);
      sign = OmrSign.minus;
      typeLabel = 'Expense';
      typeIcon = null;
      iconBg = const Color(0xFFFDECEA);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          typeIcon == null
              ? CategoryIcon(
                  (transaction.category == null || transaction.category!.isEmpty)
                      ? 'others'
                      : transaction.category!,
                  categoryTileColor(transaction.category),
                  42,
                )
              : Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(typeIcon, color: amountColor, size: 20),
                ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              DateFormat('d MMM').format(transaction.date.toLocal()),
              style: TextStyle(
                color: FinanceSurface.muted(context),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: FinanceSurface.ink(context),
                  ),
                ),
                Text(
                  typeLabel,
                  style: TextStyle(color: FinanceSurface.muted(context), fontSize: 12),
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
