import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../models/budget_models.dart';

const _ink = Color(0xFF1F4D3D);
const _muted = Color(0xFF8A8F8A);

// One category row: icon, name, used of limit, progress bar, edit, delete.
class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final BudgetModel budget;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color _accentFor(String? id) {
    switch (id) {
      case 'food':
        return const Color(0xFFFF8A65);
      case 'shopping':
        return const Color(0xFF7E57C2);
      case 'home':
        return const Color(0xFF26A69A);
      case 'wifi':
        return const Color(0xFF42A5F5);
      case 'others':
        return const Color(0xFFF4C430);
      default:
        return const Color(0xFF27AE60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = findBudgetCategory(budget.category);
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(cat?.icon ?? Icons.apps_outlined, size: 26, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedBudgetCategoryName(context, budget.category),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink,
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

// The big card with the pie chart, total, used, and remaining.
class TotalBudgetCard extends StatelessWidget {
  const TotalBudgetCard({super.key, required this.overall, this.onTap});

  final BudgetModel? overall;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final total = overall?.amountBaisa ?? 0;
    final used = overall?.usedAmountBaisa ?? 0;
    final remaining = total - used;
    final usedSlice = used < 0 ? 0 : used;
    final remainSlice = remaining < 0 ? 0 : remaining;
    final hasPie = total > 0 && (usedSlice + remainSlice) > 0;
    final remainShown = remaining < 0 ? 0 : remaining;

    return Material(
      color: Colors.white,
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
                AppI18n.t(context, en: 'Total Budget', ar: 'إجمالي الميزانية'),
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
                                    PieChartSectionData(
                                      value: remainSlice.toDouble(),
                                      color: _remainColor,
                                      radius: size * 0.168,
                                      title: '',
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2E7D5B),
                                          Color(0xFF27AE60),
                                          Color(0xFF4ECDC4),
                                        ],
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: usedSlice.toDouble() <= 0
                                          ? 0.01
                                          : usedSlice.toDouble(),
                                      color: _usedColor,
                                      radius: size * 0.178,
                                      title: '',
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF8A65),
                                          Color(0xFFFF6B6B),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : CustomPaint(painter: _EmptyRingPainter()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatBudgetOmr(total),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _LegendStat(
                      color: _usedColor,
                      label: AppI18n.t(
                        context,
                        en: 'Used          ${formatBudgetOmr(used)}',
                        ar: 'المستخدم          ${formatBudgetOmr(used)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LegendStat(
                      color: _remainColor,
                      label: AppI18n.t(
                        context,
                        en: 'Remaining  ${formatBudgetOmr(remainShown)}',
                        ar: 'المتبقي  ${formatBudgetOmr(remainShown)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendStat extends StatelessWidget {
  const _LegendStat({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _ink,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

// A simple empty circle when there is no overall budget yet.
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

// Dropdown of Food, Shopping, Home, wifi, Others. Null means no category.
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
      decoration: _fieldDecoration(large: large),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          // Empty string means "None" (Flutter dropdowns cannot use a null value).
          value: selectedId ?? (includeNone ? '' : null),
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, size: large ? 28 : 24),
          style: TextStyle(
            fontSize: fontSize,
            color: const Color(0xFF1F4D3D),
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
                    Icon(item.icon, color: Colors.black, size: large ? 26 : 24),
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

// Same white rounded look as the other form boxes.
InputDecoration _fieldDecoration({required bool large}) {
  const radius = BorderRadius.all(Radius.circular(18));
  const line = Color(0xFFE6E3DC);
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: Color(0xFF8A8F8A)),
    contentPadding: EdgeInsets.symmetric(
      horizontal: large ? 20 : 16,
      vertical: large ? 18 : 4,
    ),
    border: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: line),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: line),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Color(0xFF27AE60), width: 1.6),
    ),
  );
}
