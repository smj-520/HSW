import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../constants/categories.dart';
import '../models/budget_models.dart';
import '../models/home_finance_data.dart';
import '../services/app_i18n.dart';
import '../services/app_settings_controller.dart';
import '../services/budget_service.dart';
import '../theme/app_colors.dart';
import '../core/finance_calculator.dart';
import '../utils/finance_math.dart';
import '../utils/formatters.dart';
import '../widgets/expense_wheel.dart';
import '../widgets/home_widgets.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/set_category_budget_sheet.dart';
import 'budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.firstName,
    required this.data,
    this.now,
    this.onNotificationTap,
    this.onAddExpenseSaved,
    this.onUndoExpense,
    this.onViewAllOverview,
    this.onViewAllBills,
    this.onAddBill,
    this.onBillTap,
  });

  final String firstName;
  final HomeFinanceData data;
  final DateTime? now;
  final VoidCallback? onNotificationTap;
  final Future<String> Function({
    required String categoryId,
    required String categoryName,
    required int amountBaisa,
    required String note,
    required DateTime date,
  })? onAddExpenseSaved;
  final Future<void> Function(String id)? onUndoExpense;
  final VoidCallback? onViewAllOverview;
  final VoidCallback? onViewAllBills;
  final VoidCallback? onAddBill;
  final ValueChanged<BillItem>? onBillTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _month;
  String? _selectedId;
  List<BudgetModel> _budgetList = [];

  @override
  void initState() {
    super.initState();
    final now = widget.now ?? DateTime.now();
    _month = DateTime(now.year, now.month);
    _loadBudgets();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.transactions != widget.data.transactions) {
      _loadBudgets();
    }
  }

  Future<void> _loadBudgets() async {
    if (Firebase.apps.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final list = await BudgetService().loadBudgetList(uid);
      if (!mounted) return;
      setState(() {
        _budgetList = list;
      });
    } catch (_) {}
  }

  Map<String, int> get _budgets {
    return BudgetService().categoryBudgetMap(
      _budgetList.where((budget) {
        return sameMonth(budget.date ?? DateTime.now(), _month);
      }).toList(),
    );
  }

  List<String> get _overBudgetNames {
    final names = <String>[];
    for (final cat in kExpenseCategories) {
      final budget = _budgets[cat.id] ?? 0;
      if (budget <= 0) continue;
      final spent = _calc.categoryExpense(cat.id, _month);
      if (spent > budget) names.add(cat.label(context));
    }
    return names;
  }

  Future<void> _setCategoryBudget(ExpenseCategory cat) async {
    final saved = await showSetCategoryBudgetSheet(
      context: context,
      category: cat,
      currentBudgetBaisa: _budgets[cat.id] ?? 0,
      month: _month,
    );
    if (saved) await _loadBudgets();
  }

  Future<void> _openBudgetScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BudgetScreen()),
    );
    if (!mounted) return;
    await _loadBudgets();
  }

  bool get _canGoNext {
    final now = widget.now ?? DateTime.now();
    return DateTime(_month.year, _month.month)
        .isBefore(DateTime(now.year, now.month));
  }

  FinanceCalculator get _calc =>
      FinanceCalculator.fromFinance(widget.data.transactions);

  PeriodTotals get _monthTotals {
    final calc = _calc;
    return PeriodTotals(
      income: calc.monthlyIncome(_month),
      expense: calc.monthlyExpense(_month),
      saving: calc.monthlySaving(_month),
    );
  }

  Future<void> _onAddExpense({
    required ExpenseCategory category,
    required int amountBaisa,
    required String note,
    required DateTime date,
  }) async {
    final save = widget.onAddExpenseSaved;
    if (save == null) return;
    final name = category.label(context);
    final spentBefore = _calc.categoryExpense(category.id, _month);
    try {
      final id = await save(
        categoryId: category.id,
        categoryName: name,
        amountBaisa: amountBaisa,
        note: note,
        date: date,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      await _loadBudgets();
      if (!mounted) return;
      final amount = formatOmr(amountBaisa, sign: OmrSign.minus);
      final budget = _budgets[category.id] ?? 0;
      final spent = spentBefore + amountBaisa;
      final over = budget > 0 && spent > budget;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: over ? AppColors.homeExpense : null,
          content: Text(
            over
                ? AppI18n.t(
                    context,
                    en: '$name exceeded the monthly budget',
                    ar: 'تجاوز $name الميزانية الشهرية',
                  )
                : '$name: $amount added',
          ),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              widget.onUndoExpense?.call(id);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Invalid argument(s): ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _monthTotals;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          bottom: false,
          child: ResponsiveContent(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                responsivePagePaddingX(MediaQuery.sizeOf(context).width),
                8,
                responsivePagePaddingX(MediaQuery.sizeOf(context).width),
                100,
              ),
              children: [
                _HomeHeader(
                  firstName: widget.firstName,
                  onNotificationTap: widget.onNotificationTap,
                  hasAlerts: widget.data.bills.isNotEmpty ||
                      _overBudgetNames.isNotEmpty,
                ),
                const SizedBox(height: 16),
                BalanceCard(totalBalance: _calc.availableBalance),
                const SizedBox(height: 12),
                _HomeBudgetButton(onTap: _openBudgetScreen),
                const SizedBox(height: 18),
                _MonthHeader(
                  month: _month,
                  rtl: rtl,
                  onPrev: () {
                    setState(() {
                      _month = DateTime(_month.year, _month.month - 1);
                      _selectedId = null;
                    });
                  },
                  onNext: _canGoNext
                      ? () {
                          setState(() {
                            _month = DateTime(_month.year, _month.month + 1);
                            _selectedId = null;
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 8),
                ExpenseWheel(
                  transactions: widget.data.transactions,
                  month: _month,
                  selectedId: _selectedId,
                  onSelect: (id) => setState(() => _selectedId = id),
                  onAddExpense: _onAddExpense,
                  budgets: _budgets,
                  onSetBudget: _setCategoryBudget,
                ),
                const SizedBox(height: 16),
                OverviewStrip(
                  expense: totals.expense,
                  income: totals.income,
                  saving: totals.saving,
                ),
                const SizedBox(height: 24),
                BillsReminder(
                  bills: widget.data.bills,
                  now: widget.now,
                  onViewAll: widget.onViewAllBills ?? () {},
                  onAddBill: widget.onAddBill,
                  onBillTap: widget.onBillTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.rtl,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final bool rtl;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final locale = AppSettingsController.instance.locale.languageCode;
    final label = DateFormat('MMMM yyyy', locale).format(month);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final prevIcon = rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded;
    final nextIcon = rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: AppI18n.t(context, en: 'Previous month', ar: 'الشهر السابق'),
              onPressed: onPrev,
              icon: Icon(prevIcon),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              tooltip: AppI18n.t(context, en: 'Next month', ar: 'الشهر التالي'),
              onPressed: onNext,
              icon: Icon(nextIcon),
            ),
          ],
        ),
        Text(
          AppI18n.t(
            context,
            en: 'Tap an icon to add an expense · hold to set budget',
            ar: 'اضغط أيقونة لإضافة مصروف · اضغط مطولاً لتعيين الميزانية',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    );
  }
}

class _HomeBudgetButton extends StatelessWidget {
  const _HomeBudgetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3BC56E),
                Color(0xFF27AE60),
                Color(0xFF1F4D3D),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF27AE60).withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.pie_chart_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppI18n.t(context, en: 'Budget', ar: 'الميزانية'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppI18n.t(
                          context,
                          en: 'Set monthly limits per category',
                          ar: 'تعيين حد شهري لكل فئة',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppI18n.t(
                  context,
                  en: "Here's your financial overview",
                  ar: 'نظرة على وضعك المالي',
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: AppI18n.t(context, en: 'Notifications', ar: 'الإشعارات'),
          child: InkWell(
            onTap: onNotificationTap,
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E9E5B).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF2E9E5B),
                    size: 22,
                  ),
                ),
                if (hasAlerts)
                  Positioned(
                    right: 4,
                    top: 4,
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
        ),
      ],
    );
  }
}
