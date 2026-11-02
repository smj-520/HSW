import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../constants/category_icons.dart';
import '../models/home_finance_data.dart';
import '../services/app_i18n.dart';
import '../services/app_settings_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'category_icon.dart';

class WheelCategory {
  const WheelCategory({
    required this.id,
    required this.color,
    required this.en,
    required this.ar,
  });

  final String id;
  final Color color;
  final String en;
  final String ar;

  String label(BuildContext context) => AppI18n.t(context, en: en, ar: ar);
}

const List<WheelCategory> kExpenseWheelCategories = [
  WheelCategory(id: 'hostel_fees', color: Color(0xFF5B8DEF), en: 'Hostel fees', ar: 'رسوم السكن'),
  WheelCategory(id: 'mess_food', color: Color(0xFFE07A5F), en: 'Mess', ar: 'الطعام'),
  WheelCategory(id: 'laundry', color: Color(0xFF7ECAA0), en: 'Laundry', ar: 'غسيل'),
  WheelCategory(id: 'transport', color: Color(0xFF7B8CDE), en: 'Transport', ar: 'مواصلات'),
  WheelCategory(id: 'study', color: Color(0xFF7E57C2), en: 'Study', ar: 'دراسة'),
  WheelCategory(id: 'mobile', color: Color(0xFF5DA9E9), en: 'Mobile', ar: 'جوال'),
  WheelCategory(id: 'health', color: Color(0xFFE07A9A), en: 'Health', ar: 'صحة'),
  WheelCategory(id: 'personal_care', color: Color(0xFF86C5D8), en: 'Personal care', ar: 'عناية شخصية'),
  WheelCategory(id: 'entertainment', color: Color(0xFFE6B325), en: 'Entertainment', ar: 'ترفيه'),
  WheelCategory(id: 'gifts_family', color: Color(0xFFE8A0BF), en: 'Gifts', ar: 'هدايا'),
  WheelCategory(id: 'groceries', color: Color(0xFFD46A6A), en: 'Groceries', ar: 'بقالة'),
  WheelCategory(id: 'emergency', color: Color(0xFFF4C430), en: 'Emergency', ar: 'طوارئ'),
];

String? normalizeWheelCategory(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    return categoryIconKey(raw);
  } catch (_) {
    return null;
  }
}

class ExpenseWheel extends StatefulWidget {
  const ExpenseWheel({
    super.key,
    required this.transactions,
    required this.onAddExpense,
    required this.onUndoExpense,
  });

  final List<FinanceTransaction> transactions;
  final Future<String> Function({
    required String categoryId,
    required String categoryName,
    required int amountBaisa,
    String note,
  }) onAddExpense;
  final Future<void> Function(String id) onUndoExpense;

  @override
  State<ExpenseWheel> createState() => _ExpenseWheelState();
}

class _ExpenseWheelState extends State<ExpenseWheel> {
  late DateTime _month;
  String? _selectedId;
  int? _draftBaisa;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  DateTime get _periodStart => DateTime(_month.year, _month.month, 1);

  DateTime get _periodEnd {
    final now = DateTime.now();
    final last = DateTime(_month.year, _month.month + 1, 0, 23, 59, 59, 999);
    final isCurrent =
        _month.year == now.year && _month.month == now.month;
    if (isCurrent) {
      return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    }
    return last;
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return DateTime(_month.year, _month.month)
        .isBefore(DateTime(now.year, now.month));
  }

  bool _inPeriod(DateTime raw) {
    final d = raw.toLocal();
    return !d.isBefore(_periodStart) && !d.isAfter(_periodEnd);
  }

  List<FinanceTransaction> get _periodRows {
    return widget.transactions.where((tx) => _inPeriod(tx.createdAt)).toList();
  }

  int get _periodIncome {
    var n = 0;
    for (final tx in _periodRows) {
      if (tx.kind == TransactionKind.income) n += tx.amountBaisa;
    }
    return n;
  }

  int get _periodExpense {
    var n = 0;
    for (final tx in _periodRows) {
      if (tx.kind == TransactionKind.expense) n += tx.amountBaisa;
    }
    return n;
  }

  Map<String, int> get _spendByCategory {
    final map = <String, int>{};
    for (final tx in _periodRows) {
      if (tx.kind != TransactionKind.expense) continue;
      final id = normalizeWheelCategory(tx.category);
      if (id == null) continue;
      map[id] = (map[id] ?? 0) + tx.amountBaisa;
    }
    return map;
  }

  Future<void> _openAddSheet(WheelCategory category) async {
    setState(() {
      _selectedId = category.id;
      _draftBaisa = null;
    });
    final result = await showModalBottomSheet<_WheelDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: _WheelAmountSheet(
            category: category,
            onDraftChanged: (baisa) {
              if (!mounted) return;
              setState(() => _draftBaisa = baisa);
            },
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    setState(() => _draftBaisa = null);
    if (result == null) return;

    final id = await widget.onAddExpense(
      categoryId: category.id,
      categoryName: category.label(context),
      amountBaisa: result.amountBaisa,
      note: result.note,
    );
    if (!mounted) return;
    final label = category.label(context);
    final amount = formatOmr(result.amountBaisa, sign: OmrSign.minus);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label: $amount ${AppI18n.t(context, en: 'added', ar: 'أُضيف')}'),
        action: SnackBarAction(
          label: AppI18n.t(context, en: 'UNDO', ar: 'تراجع'),
          onPressed: () {
            widget.onUndoExpense(id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppSettingsController.instance.locale.languageCode;
    final endLabel = DateFormat('EEE, d MMMM', locale).format(_periodEnd);
    final spend = _spendByCategory;
    final expense = _periodExpense;
    final income = _periodIncome;
    final hasSlices = spend.values.any((v) => v > 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: AppI18n.t(context, en: 'Previous month', ar: 'الشهر السابق'),
                  onPressed: () {
                    setState(() {
                      _month = DateTime(_month.year, _month.month - 1);
                      _selectedId = null;
                    });
                  },
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: AppColors.homePrimary,
                ),
                Expanded(
                  child: Text(
                    endLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppI18n.t(context, en: 'Next month', ar: 'الشهر التالي'),
                  onPressed: _canGoNext
                      ? () {
                          setState(() {
                            _month = DateTime(_month.year, _month.month + 1);
                            _selectedId = null;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: AppColors.homePrimary,
                ),
              ],
            ),
          ),
          if (_draftBaisa != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                formatOmr(_draftBaisa!, sign: OmrSign.minus),
                style: TextStyle(
                  color: AppColors.homeExpense,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth.clamp(280.0, 560.0);
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: SizedBox(
                width: size,
                height: size,
                child: _WheelBoard(
                  size: size,
                  spend: spend,
                  totalExpense: expense,
                  income: income,
                  selectedId: _selectedId,
                  hasSlices: hasSlices,
                  onSelect: (id) {
                    WheelCategory? cat;
                    for (final item in kExpenseWheelCategories) {
                      if (item.id == id) {
                        cat = item;
                        break;
                      }
                    }
                    if (cat == null) {
                      setState(() => _selectedId = id);
                      return;
                    }
                    _openAddSheet(cat);
                  },
                  onSelectSlice: (id) => setState(() => _selectedId = id),
                ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WheelBoard extends StatelessWidget {
  const _WheelBoard({
    required this.size,
    required this.spend,
    required this.totalExpense,
    required this.income,
    required this.selectedId,
    required this.hasSlices,
    required this.onSelect,
    required this.onSelectSlice,
  });

  final double size;
  final Map<String, int> spend;
  final int totalExpense;
  final int income;
  final String? selectedId;
  final bool hasSlices;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onSelectSlice;

  static const _positions = <String, Offset>{
    'hostel_fees': Offset(0.28, 0.14),
    'mess_food': Offset(0.50, 0.12),
    'laundry': Offset(0.72, 0.14),
    'transport': Offset(0.88, 0.32),
    'study': Offset(0.90, 0.50),
    'mobile': Offset(0.88, 0.68),
    'health': Offset(0.28, 0.86),
    'personal_care': Offset(0.50, 0.88),
    'entertainment': Offset(0.72, 0.86),
    'gifts_family': Offset(0.12, 0.32),
    'groceries': Offset(0.10, 0.50),
    'emergency': Offset(0.12, 0.68),
  };

  List<PieChartSectionData> _sections(double donutSize) {
    final ordered = <WheelCategory>[];
    for (final cat in kExpenseWheelCategories) {
      if ((spend[cat.id] ?? 0) > 0) ordered.add(cat);
    }
    if (ordered.isEmpty) return const [];
    return [
      for (final cat in ordered)
        PieChartSectionData(
          value: (spend[cat.id] ?? 0).toDouble(),
          color: cat.color,
          radius: selectedId == cat.id ? donutSize * 0.16 : donutSize * 0.13,
          title: '',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final donutSize = size * 0.46;
    final sections = _sections(donutSize);
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final iconSize = tablet ? 72.0 : (size * 0.105).clamp(56.0, 64.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (selectedId != null)
          CustomPaint(
            size: Size(size, size),
            painter: _SpokePainter(
              from: Offset(size / 2, size / 2),
              to: Offset(
                _positions[selectedId]!.dx * size,
                _positions[selectedId]!.dy * size,
              ),
              color: () {
                for (final cat in kExpenseWheelCategories) {
                  if (cat.id == selectedId) return cat.color;
                }
                return AppColors.homeAccent;
              }(),
            ),
          ),
        Center(
          child: SizedBox(
            width: donutSize,
            height: donutSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                hasSlices
                    ? PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: donutSize * 0.32,
                          startDegreeOffset: -90,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              if (!event.isInterestedForInteractions) return;
                              final index =
                                  response?.touchedSection?.touchedSectionIndex;
                              if (index == null || index < 0) return;
                              final ordered = kExpenseWheelCategories
                                  .where((c) => (spend[c.id] ?? 0) > 0)
                                  .toList();
                              if (index >= ordered.length) return;
                              onSelectSlice(ordered[index].id);
                            },
                          ),
                          sections: sections,
                        ),
                      )
                    : CustomPaint(
                        size: Size(donutSize, donutSize),
                        painter: const _EmptyDonutPainter(),
                      ),
                Padding(
                  padding: EdgeInsets.all(donutSize * 0.18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        child: Text(
                          formatOmr(income),
                          style: TextStyle(
                            color: AppColors.homeIncome,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        child: Text(
                          formatOmr(totalExpense, sign: OmrSign.minus),
                          style: TextStyle(
                            color: AppColors.homeExpense,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final cat in kExpenseWheelCategories)
          Positioned(
            left: _positions[cat.id]!.dx * size - iconSize * 0.58,
            top: _positions[cat.id]!.dy * size - iconSize * 0.58,
            child: GestureDetector(
              onTap: () => onSelect(cat.id),
              child: CategoryIcon(
                cat.id,
                cat.color,
                iconSize,
                badgePercent: totalExpense > 0 && (spend[cat.id] ?? 0) > 0
                    ? (((spend[cat.id] ?? 0) / totalExpense) * 100).round()
                    : null,
                selected: selectedId == cat.id,
              ),
            ),
          ),
      ],
    );
  }
}

class _SpokePainter extends CustomPainter {
  const _SpokePainter({
    required this.from,
    required this.to,
    required this.color,
  });

  final Offset from;
  final Offset to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);
  }

  @override
  bool shouldRepaint(covariant _SpokePainter oldDelegate) {
    return oldDelegate.to != to || oldDelegate.color != color;
  }
}

class _EmptyDonutPainter extends CustomPainter {
  const _EmptyDonutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final paint = Paint()
      ..color = const Color(0xFFD8DDD8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12;
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WheelDraft {
  const _WheelDraft({required this.amountBaisa, required this.note});

  final int amountBaisa;
  final String note;
}

class _WheelAmountSheet extends StatefulWidget {
  const _WheelAmountSheet({
    required this.category,
    required this.onDraftChanged,
  });

  final WheelCategory category;
  final ValueChanged<int?> onDraftChanged;

  @override
  State<_WheelAmountSheet> createState() => _WheelAmountSheetState();
}

class _WheelAmountSheetState extends State<_WheelAmountSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final baisa = parseOmrToBaisa(_amount.text);
    if (baisa == null) {
      setState(() {
        _error = AppI18n.t(
          context,
          en: 'Enter a valid amount',
          ar: 'أدخل مبلغاً صحيحاً',
        );
      });
      return;
    }
    Navigator.of(context).pop(
      _WheelDraft(amountBaisa: baisa, note: _note.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CategoryIcon(
                widget.category.id,
                widget.category.color,
                40,
              ),
              const SizedBox(width: 10),
              Text(
                widget.category.label(context),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.homePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: AppI18n.t(context, en: 'Amount (OMR)', ar: 'المبلغ (ر.ع)'),
              hintText: '5.000',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (value) {
              widget.onDraftChanged(parseOmrToBaisa(value));
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              labelText: AppI18n.t(context, en: 'Note (optional)', ar: 'ملاحظة (اختياري)'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.homeAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(AppI18n.t(context, en: 'Save', ar: 'حفظ')),
          ),
        ],
      ),
    );
  }
}
