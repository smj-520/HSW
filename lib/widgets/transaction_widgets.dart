import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './report_widgets.dart';
import '../services/app_i18n.dart';
import '../utils/formatters.dart';
import '../models/transaction_model.dart';
import 'category_icon.dart';

// One row: day, title, type, and the amount in the right color.
class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final date = transaction.date.toLocal();
    final Color amountColor;
    final Color accent;
    final OmrSign sign;
    final String typeLabel;
    final IconData? typeIcon;
    if (transaction.isIncome) {
      amountColor = const Color(0xFF27AE60);
      accent = const Color(0xFF27AE60);
      sign = OmrSign.plus;
      typeLabel = AppI18n.t(context, en: 'Income', ar: 'دخل');
      typeIcon = Icons.south_west_rounded;
    } else if (transaction.isSaving) {
      amountColor = const Color(0xFFD4A017);
      accent = const Color(0xFFD4A017);
      sign = OmrSign.plus;
      typeLabel = AppI18n.t(context, en: 'Saving', ar: 'ادخار');
      typeIcon = Icons.savings_outlined;
    } else {
      amountColor = const Color(0xFFE74C3C);
      accent = const Color(0xFFE74C3C);
      sign = OmrSign.minus;
      typeLabel = AppI18n.t(context, en: 'Expense', ar: 'مصروف');
      typeIcon = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          typeIcon == null
              ? CategoryIcon(
                  (transaction.category == null || transaction.category!.isEmpty)
                      ? 'others'
                      : transaction.category!,
                  categoryTileColor(transaction.category),
                  40,
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: accent, size: 20),
                ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Text(
                  DateFormat('d MMM').format(date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM').format(date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF1F4D3D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  typeLabel,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
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

// One bar on the expenses chart.
class CategoryBar {
  const CategoryBar({
    required this.name,
    required this.amountBaisa,
    required this.percent,
    required this.color,
    this.categoryId,
  });

  final String name;
  final int amountBaisa;
  final double percent;
  final Color color;
  final String? categoryId;
}

// Bar chart of expenses by category, plus the top percentages.
class SummaryChart extends StatelessWidget {
  const SummaryChart({super.key, required this.bars});

  final List<CategoryBar> bars;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No expenses yet',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    var maxAmount = 1;
    for (final bar in bars) {
      if (bar.amountBaisa > maxAmount) maxAmount = bar.amountBaisa;
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
                for (var i = 0; i < bars.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: bars[i].amountBaisa.toDouble(),
                        color: bars[i].color,
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
              for (final bar in bars)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: CategoryIcon(
                          bar.categoryId ?? 'others',
                          bar.color,
                          22,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          bar.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: FinanceSurface.ink(context),
                          ),
                        ),
                      ),
                      Text(
                        '${(bar.percent * 100).round()}%',
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

// White card: total income, total expenses, and a green/red bar.
class IncomeExpenseCard extends StatelessWidget {
  const IncomeExpenseCard({
    super.key,
    required this.incomeBaisa,
    required this.expenseBaisa,
  });

  final int incomeBaisa;
  final int expenseBaisa;

  @override
  Widget build(BuildContext context) {
    final total = incomeBaisa + expenseBaisa;
    final incomePart = total <= 0 ? 0.0 : incomeBaisa / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: FinanceSurface.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppI18n.t(context, en: 'Income vs Expenses', ar: 'الدخل مقابل المصروفات'),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: FinanceSurface.ink(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppI18n.t(context, en: 'Income', ar: 'الدخل'),
                      style: TextStyle(
                        color: FinanceSurface.muted(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatOmr(incomeBaisa, sign: OmrSign.plus),
                      style: TextStyle(
                        color: Color(0xFF27AE60),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppI18n.t(context, en: 'Expenses', ar: 'المصروفات'),
                      style: TextStyle(
                        color: FinanceSurface.muted(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatOmr(expenseBaisa, sign: OmrSign.minus),
                      style: TextStyle(
                        color: Color(0xFFE74C3C),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (total <= 0)
                    const Expanded(child: ColoredBox(color: Color(0xFFE8E8E8)))
                  else ...[
                    if (incomePart > 0)
                      Expanded(
                        flex: (incomePart * 1000).round().clamp(1, 1000),
                        child: const ColoredBox(color: Color(0xFF27AE60)),
                      ),
                    if (incomePart < 1)
                      Expanded(
                        flex: ((1 - incomePart) * 1000).round().clamp(1, 1000),
                        child: const ColoredBox(color: Color(0xFFE74C3C)),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
