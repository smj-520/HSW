import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../core/budget_calculator.dart';
import '../core/money.dart';
import '../services/app_i18n.dart';
import '../models/budget_models.dart';
import 'category_icon.dart';

const _ink = Color(0xFF1F4D3D);
const _muted = Color(0xFF8A8F8A);

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.needsAdjusting = false,
  });

  final BudgetModel budget;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool needsAdjusting;

  Color _accentFor(String? id) => categoryTileColor(id);

  @override
  Widget build(BuildContext context) {
    final used = budget.usedAmountBaisa;
    final limit = budget.amountBaisa;
    final percent = limit <= 0 ? 0.0 : used / limit;
    final accent = _accentFor(budget.category);
    final Color barColor;
    if (percent > 1) {
      barColor = Colors.red;
    } else if (percent >= 0.8) {
      barColor = Colors.orange;
    } else {
      barColor = const Color(0xFF27AE60);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: needsAdjusting
                  ? Border.all(color: const Color(0xFFE24B4A), width: 1.4)
                  : null,
              color: needsAdjusting
                  ? const Color(0xFFE24B4A).withValues(alpha: 0.06)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F4D3D).withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CategoryIcon(
                  budget.category ?? 'others',
                  accent,
                  48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedBudgetCategoryName(context, budget.category),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppI18n.t(
                          context,
                          en: '${formatBudgetOmr(used)} of ${formatBudgetOmr(limit)}',
                          ar: '${formatBudgetOmr(used)} من ${formatBudgetOmr(limit)}',
                        ),
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent > 1 ? 1 : percent,
                          minHeight: 7,
                          color: barColor,
                          backgroundColor: const Color(0xFFE8E8E8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: _ink.withValues(alpha: 0.75)),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: _ink.withValues(alpha: 0.75)),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _usedColor = Color(0xFFFF6B6B);
const _remainColor = Color(0xFF27AE60);
const _allocatedColor = Color(0xFF42A5F5);

class TotalBudgetCard extends StatelessWidget {
  const TotalBudgetCard({
    super.key,
    required this.calculator,
    this.onTap,
  });

  final BudgetCalculator calculator;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final income = calculator.income;
    final allocated = calculator.totalAllocated < 0 ? 0 : calculator.totalAllocated;
    final unallocated = calculator.unallocated;
    final spent = calculator.totalSpent < 0 ? 0 : calculator.totalSpent;
    final balance = calculator.totalBalance < 0 ? 0 : calculator.totalBalance;
    final over = calculator.isOverAllocated;
    final categorySlices = <({ExpenseCategory cat, int amount})>[
      for (final cat in kExpenseCategories)
        if ((calculator.categoryLimits[cat.id] ?? 0) > 0)
          (cat: cat, amount: calculator.categoryLimits[cat.id]!),
    ];
    final hasPie = categorySlices.isNotEmpty || unallocated > 0;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F4D3D).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                AppI18n.t(context, en: 'This month', ar: 'هذا الشهر'),
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = (constraints.maxWidth * 0.72).clamp(188.0, 236.0);
                  return SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        hasPie
                            ? PieChart(
                                PieChartData(
                                  sectionsSpace: 3.5,
                                  centerSpaceRadius: size * 0.30,
                                  startDegreeOffset: -90,
                                  pieTouchData: PieTouchData(enabled: false),
                                  sections: [
                                    for (final slice in categorySlices)
                                      PieChartSectionData(
                                        value: slice.amount.toDouble(),
                                        color: slice.cat.color,
                                        radius: size * 0.178,
                                        title: '',
                                      ),
                                    if (unallocated > 0)
                                      PieChartSectionData(
                                        value: unallocated.toDouble(),
                                        color: const Color(0xFFD9E8DF),
                                        radius: size * 0.168,
                                        title: '',
                                      ),
                                  ],
                                ),
                              )
                            : CustomPaint(painter: _EmptyRingPainter()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppI18n.t(context, en: 'Total Balance', ar: 'الرصيد الكلي'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  Money.format(balance),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _SummaryChip(
                    color: const Color(0xFF1F4D3D),
                    label: AppI18n.t(context, en: 'Total Balance', ar: 'الرصيد الكلي'),
                    value: Money.format(balance),
                  ),
                  _SummaryChip(
                    color: _remainColor,
                    label: AppI18n.t(context, en: 'Income', ar: 'الدخل'),
                    value: Money.format(income),
                  ),
                  _SummaryChip(
                    color: _allocatedColor,
                    label: AppI18n.t(context, en: 'Allocated', ar: 'المخصص'),
                    value: Money.format(allocated),
                  ),
                  _SummaryChip(
                    color: over ? _usedColor : _remainColor,
                    label: AppI18n.t(context, en: 'Unallocated', ar: 'غير المخصص'),
                    value: Money.format(unallocated),
                  ),
                  _SummaryChip(
                    color: _usedColor,
                    label: AppI18n.t(context, en: 'Spent', ar: 'المصروف'),
                    value: Money.format(spent),
                  ),
                ],
              ),
              if (categorySlices.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final slice in categorySlices)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: slice.cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            slice.cat.shortLabel(context),
                            style: const TextStyle(fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                AppI18n.t(
                  context,
                  en: 'Donut: allocated by category',
                  ar: 'الرسم: المخصص حسب الفئة',
                ),
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink,
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

class _EmptyRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE8E6E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF27AE60), Color(0xFF4ECDC4), Color(0xFF6C63FF)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    super.key,
    required this.selectedId,
    required this.onChanged,
    this.includeNone = false,
    this.large = false,
  });

  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool includeNone;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 18.0 : 16.0;
    return InputDecorator(
      decoration: _fieldDecoration(context, large: large),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId ?? (includeNone ? '' : null),
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, size: large ? 28 : 24),
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(
            fontSize: fontSize,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          hint: Text(
            includeNone
                ? AppI18n.t(context, en: 'None', ar: 'بدون')
                : AppI18n.t(context, en: 'Select Category', ar: 'اختر الفئة'),
            style: TextStyle(
              fontSize: fontSize,
              color: const Color(0xFF8A8F8A),
            ),
          ),
          items: [
            if (includeNone)
              DropdownMenuItem(
                value: '',
                child: Text(AppI18n.t(context, en: 'None', ar: 'بدون')),
              ),
            for (final item in budgetCategories)
              DropdownMenuItem(
                value: item.id,
                child: Row(
                  children: [
                    CategoryIcon(
                      item.id,
                      categoryTileColor(item.id),
                      large ? 28.0 : 24.0,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      localizedBudgetCategoryName(context, item.id),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (id) => onChanged((id == null || id.isEmpty) ? null : id),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context, {required bool large}) {
  const radius = BorderRadius.all(Radius.circular(18));
  final line = Theme.of(context).colorScheme.outline.withValues(alpha: 0.55);
  return InputDecoration(
    filled: true,
    fillColor: Theme.of(context).cardColor,
    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    contentPadding: EdgeInsets.symmetric(
      horizontal: large ? 20 : 16,
      vertical: large ? 18 : 4,
    ),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: line),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Color(0xFF27AE60), width: 1.6),
    ),
  );
}
