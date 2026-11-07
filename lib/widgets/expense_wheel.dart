import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../core/finance_calculator.dart';
import '../models/budget_models.dart';
import '../models/home_finance_data.dart';
import '../services/app_i18n.dart';
import '../utils/finance_math.dart';
import '../utils/formatters.dart';
import 'add_expense_sheet.dart';
import 'category_tile.dart';

class ExpenseWheel extends StatelessWidget {
  const ExpenseWheel({
    super.key,
    required this.transactions,
    required this.month,
    required this.selectedId,
    required this.onSelect,
    required this.onAddExpense,
    this.budgets = const {},
    this.onSetBudget,
  });

  final List<FinanceTransaction> transactions;
  final DateTime month;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final Future<void> Function({
    required ExpenseCategory category,
    required int amountBaisa,
    required String note,
    required DateTime date,
  }) onAddExpense;
  final Map<String, int> budgets;
  final Future<void> Function(ExpenseCategory category)? onSetBudget;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = MediaQuery.sizeOf(context).width;
        final maxW = constraints.maxWidth;
        final w = (maxW.isFinite && maxW > 0 ? maxW : screenW).clamp(280.0, 520.0);
        final h = w * (392 / 340);
        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: _WheelBoard(
              width: w,
              height: h,
              transactions: transactions,
              month: month,
              selectedId: selectedId,
              onSelect: onSelect,
              onAddExpense: onAddExpense,
              budgets: budgets,
              onSetBudget: onSetBudget,
            ),
          ),
        );
      },
    );
  }
}

class _WheelBoard extends StatelessWidget {
  const _WheelBoard({
    required this.width,
    required this.height,
    required this.transactions,
    required this.month,
    required this.selectedId,
    required this.onSelect,
    required this.onAddExpense,
    required this.budgets,
    this.onSetBudget,
  });

  final double width;
  final double height;
  final List<FinanceTransaction> transactions;
  final DateTime month;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final Future<void> Function({
    required ExpenseCategory category,
    required int amountBaisa,
    required String note,
    required DateTime date,
  }) onAddExpense;
  final Map<String, int> budgets;
  final Future<void> Function(ExpenseCategory category)? onSetBudget;

  FinanceCalculator get _calc => FinanceCalculator.fromFinance(transactions);

  Map<String, int> get _spend {
    final spend = _calc.categorySpend(month);
    return {
      for (final cat in kExpenseCategories) cat.id: spend[cat.id] ?? 0,
    };
  }

  Future<void> _openSheet(BuildContext context, ExpenseCategory cat) async {
    onSelect(cat.id);
    final result = await showAddExpenseSheet(
      context: context,
      category: cat,
      initialDate: DateTime.now(),
      availableBaisa: _calc.availableBalance,
    );
    if (result == null) return;
    await onAddExpense(
      category: cat,
      amountBaisa: result.amountBaisa,
      note: result.note,
      date: result.date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spend = _spend;
    final calc = _calc;
    final totals = PeriodTotals(
      income: calc.monthlyIncome(month),
      expense: calc.monthlyExpense(month),
      saving: calc.monthlySaving(month),
    );
    int budgetFor(String id) {
      final direct = budgets[id] ?? 0;
      if (direct > 0) return direct;
      var sum = 0;
      for (final entry in budgets.entries) {
        if (normalizeExpenseCategoryId(entry.key) == id) {
          sum += entry.value;
        }
      }
      return sum;
    }

    final budgetByCat = <String, int>{
      for (final cat in kExpenseCategories) cat.id: budgetFor(cat.id),
    };
    final hasAllocated = budgetByCat.values.any((n) => n > 0);
    final sliceAmounts = <String, int>{
      for (final cat in kExpenseCategories)
        cat.id: hasAllocated
            ? (budgetByCat[cat.id] ?? 0)
            : (spend[cat.id] ?? 0),
    };
    final amounts = [
      for (final cat in kExpenseCategories) sliceAmounts[cat.id] ?? 0,
    ];
    final percents = FinanceCalculator.largestRemainderPercents(amounts);
    final sliceTotal = amounts.fold<int>(0, (sum, n) => sum + n);
    final totalExpense = [for (final cat in kExpenseCategories) spend[cat.id] ?? 0]
        .fold<int>(0, (sum, n) => sum + n);
    final hasSlices = sliceTotal > 0;
    final tileSize = (width * 0.124).clamp(42.0, 64.0);

    return SizedBox(
      width: width,
      height: height,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${month.year}-${month.month}-$sliceTotal-$totalExpense'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, reveal, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final paintSize = Size(
                      box.maxWidth.isFinite && box.maxWidth > 0
                          ? box.maxWidth
                          : width,
                      box.maxHeight.isFinite && box.maxHeight > 0
                          ? box.maxHeight
                          : height,
                    );
                    return GestureDetector(
                      onTapDown: (details) {
                        final id = hitWheelSlice(
                          local: details.localPosition,
                          size: paintSize,
                          spend: sliceAmounts,
                        );
                        onSelect(id);
                      },
                      child: SizedBox.expand(
                        child: CustomPaint(
                          painter: _DonutPainter(
                            spend: spend,
                            budgets: budgetByCat,
                            sliceAmounts: sliceAmounts,
                            selectedId: selectedId,
                            reveal: hasSlices
                                ? reveal.clamp(0.2, 1.0)
                                : 0,
                            hasSlices: hasSlices,
                            trackColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    if (selectedId != null) {
                      onSelect(null);
                    }
                  },
                  child: SizedBox(
                    width: width * 0.28,
                    height: width * 0.28,
                    child: FittedBox(
                      child: _CenterLabel(
                        selectedId: selectedId,
                        spend: spend,
                        budgets: budgetByCat,
                        percents: percents,
                        income: totals.income,
                        expense: totals.expense,
                        hasSlices: hasSlices,
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < kExpenseCategories.length; i++)
                Builder(
                  builder: (context) {
                    final cat = kExpenseCategories[i];
                    final frac = kExpenseTileFractions[cat.id]!;
                    final amount = spend[cat.id] ?? 0;
                    final budget = budgetByCat[cat.id] ?? 0;
                    final pct = budgetUsagePercent(
                      spentBaisa: amount,
                      budgetBaisa: budget,
                    );
                    return Positioned(
                      left: frac.dx * width - (tileSize + 8) / 2,
                      top: frac.dy * height - tileSize / 2,
                      child: CategoryTile(
                        category: cat,
                        size: tileSize,
                        percent: pct,
                        badgeColor:
                            pct == null ? null : budgetUsageColor(pct),
                        selected: selectedId == cat.id,
                        onTap: () => _openSheet(context, cat),
                        onLongPress: onSetBudget == null
                            ? null
                            : () => onSetBudget!(cat),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({
    required this.selectedId,
    required this.spend,
    required this.budgets,
    required this.percents,
    required this.income,
    required this.expense,
    required this.hasSlices,
  });

  final String? selectedId;
  final Map<String, int> spend;
  final Map<String, int> budgets;
  final List<int> percents;
  final int income;
  final int expense;
  final bool hasSlices;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (!hasSlices && selectedId == null) {
      return Text(
        AppI18n.t(context, en: 'No expenses yet', ar: 'لا توجد مصاريف'),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: muted),
      );
    }
    final selected = expenseCategoryById(selectedId);
    if (selected != null) {
      final amount = spend[selected.id] ?? 0;
      final budget = budgets[selected.id] ?? 0;
      final idx = kExpenseCategories.indexWhere((c) => c.id == selected.id);
      final pct = idx >= 0 ? percents[idx] : 0;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selected.label(context),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            formatOmr(amount, sign: OmrSign.minus),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE24B4A),
            ),
          ),
          if (budget > 0)
            Text(
              formatOmr(budget),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected.color,
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppI18n.t(context, en: 'This month', ar: 'هذا الشهر'),
          style: TextStyle(fontSize: 11, color: muted),
        ),
        Text(
          formatOmr(income),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E9E5B),
          ),
        ),
        Text(
          formatOmr(expense, sign: OmrSign.minus),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFFE24B4A),
          ),
        ),
      ],
    );
  }
}

String? hitWheelSlice({
  required Offset local,
  required Size size,
  required Map<String, int> spend,
}) {
  final c = Offset(size.width / 2, size.height / 2);
  final r = math.min(size.width, size.height) * 0.265;
  final stroke = r * 0.32;
  final d = (local - c).distance;
  if (d < r - stroke || d > r + stroke + 8) return null;
  final slices = <({ExpenseCategory cat, int amount})>[];
  for (final cat in kExpenseCategories) {
    final n = spend[cat.id] ?? 0;
    if (n > 0) slices.add((cat: cat, amount: n));
  }
  if (slices.isEmpty) return null;
  final total = slices.fold<int>(0, (s, e) => s + e.amount).toDouble();
  final gap = slices.length == 1 ? 0.0 : 7.0 / r;
  final usable = math.pi * 2 - gap * slices.length;
  var start = -math.pi / 2 + gap / 2;
  var ang = math.atan2(local.dy - c.dy, local.dx - c.dx);
  for (final slice in slices) {
    final sweep = (slice.amount / total) * usable;
    var a = ang;
    while (a < start) {
      a += math.pi * 2;
    }
    if (a >= start && a <= start + sweep) return slice.cat.id;
    start += sweep + gap;
  }
  return null;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.spend,
    required this.budgets,
    required this.sliceAmounts,
    required this.selectedId,
    required this.reveal,
    required this.hasSlices,
    required this.trackColor,
  });

  final Map<String, int> spend;
  final Map<String, int> budgets;
  final Map<String, int> sliceAmounts;
  final String? selectedId;
  final double reveal;
  final bool hasSlices;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 8 || size.height < 8) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.265;
    final stroke = r * 0.36;

    final track = Paint()
      ..isAntiAlias = true
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);

    final slices = <({ExpenseCategory cat, int amount, int spent, int budget})>[];
    for (final cat in kExpenseCategories) {
      final amount = sliceAmounts[cat.id] ?? 0;
      if (amount <= 0) continue;
      slices.add((
        cat: cat,
        amount: amount,
        spent: spend[cat.id] ?? 0,
        budget: budgets[cat.id] ?? 0,
      ));
    }
    final total = slices.fold<int>(0, (s, e) => s + e.amount).toDouble();
    if (total <= 0) return;

    final t = reveal <= 0 ? 1.0 : reveal.clamp(0.0, 1.0);
    final gapPx = 8.0;
    final gap = slices.length == 1 ? 0.0 : gapPx / r;
    final usable = (math.pi * 2 - gap * slices.length) * t;
    if (usable <= 0) return;
    var start = -math.pi / 2 + gap / 2;

    for (final slice in slices) {
      final sweep = (slice.amount / total) * usable;
      if (sweep <= 0.001) {
        start += gap;
        continue;
      }
      final selected = selectedId == slice.cat.id;
      final radius = selected ? r + 3 : r;
      final width = selected ? stroke * 1.18 : stroke;
      final rect = Rect.fromCircle(center: c, radius: radius);
      final allocatedPaint = Paint()
        ..isAntiAlias = true
        ..color = slice.cat.color.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, allocatedPaint);
      if (slice.budget > 0 && slice.spent > 0) {
        final spentSweep = sweep * (slice.spent / slice.budget).clamp(0.0, 1.0);
        if (spentSweep > 0.001) {
          final spentPaint = Paint()
            ..isAntiAlias = true
            ..color = slice.cat.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeCap = StrokeCap.butt;
          canvas.drawArc(rect, start, spentSweep, false, spentPaint);
        }
      } else if (slice.budget <= 0) {
        final spentPaint = Paint()
          ..isAntiAlias = true
          ..color = slice.cat.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect, start, sweep, false, spentPaint);
      }
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.reveal != reveal ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.hasSlices != hasSlices ||
        oldDelegate.spend != spend ||
        oldDelegate.budgets != budgets ||
        oldDelegate.sliceAmounts != sliceAmounts;
  }
}
