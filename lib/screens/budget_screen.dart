import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../core/budget_calculator.dart';
import '../models/budget_models.dart';
import '../models/home_finance_data.dart';
import '../services/app_i18n.dart';
import '../services/budget_service.dart';
import '../services/finance_repository.dart';
import '../widgets/budget_widgets.dart';
import '../widgets/responsive_layout.dart';
import './add_budget_screen.dart';
import './add_transaction_screen.dart';
import './budget_details_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetService = BudgetService();
  final _financeRepo = FinanceRepository();
  List<BudgetModel> budgetList = [];
  List<FinanceTransaction> _transactions = [];
  bool isLoading = true;
  String errorMessage = '';
  StreamSubscription<HomeFinanceData>? _financeSub;
  StreamSubscription<Object?>? _budgetSub;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    _financeSub?.cancel();
    _budgetSub?.cancel();
    super.dispose();
  }

  String? sessionUid() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  void _listen() {
    final uid = sessionUid();
    if (uid == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'You must be signed in.';
      });
      return;
    }
    _financeSub = _financeRepo.watch(uid).listen((data) {
      _transactions = data.transactions;
      loadBudgets();
    }, onError: (_) {});
    _budgetSub = _budgetService.watchRaw(uid).listen((_) {
      loadBudgets();
    }, onError: (_) {});
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    final uid = sessionUid();
    if (uid == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'You must be signed in.';
      });
      return;
    }
    try {
      final list = await _budgetService.loadBudgetList(uid);
      if (!mounted) return;
      setState(() {
        budgetList = list;
        isLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not load budgets. Check Firebase rules.';
      });
    }
  }

  BudgetCalculator get _calculator {
    return BudgetCalculator.fromMonth(
      transactions: _transactions,
      budgets: budgetList,
      month: DateTime.now(),
    );
  }

  Future<void> openOverall() async {
    if (!_calculator.canAddBudgets) {
      await openAddIncome();
      return;
    }
    final overall = _budgetService.findOverall(
      budgetList,
      periodDate: DateTime.now(),
    );
    if (overall == null) {
      await openAddBudget();
      return;
    }
    await openDetails(overall);
  }

  Future<void> openDetails(BudgetModel budget) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BudgetDetailsScreen(budget: budget),
      ),
    );
    await loadBudgets();
  }

  Future<void> openAddIncome() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(
          kind: TransactionKind.income,
        ),
      ),
    );
    await loadBudgets();
  }

  Future<void> openAddBudget() async {
    if (!_calculator.canAddBudgets) {
      await openAddIncome();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
    );
    await loadBudgets();
  }

  Future<void> openEditBudget(BudgetModel budget) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(budget: budget),
      ),
    );
    await loadBudgets();
  }

  Future<void> deleteBudget(BudgetModel budget) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppI18n.t(
              context,
              en: 'Are you sure you want to delete this budget?',
              ar: 'هل أنت متأكد أنك تريد حذف هذه الميزانية؟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppI18n.t(context, en: 'Cancel', ar: 'إلغاء')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppI18n.t(context, en: 'Delete', ar: 'حذف'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final uid = sessionUid();
    if (uid == null) return;
    try {
      await _budgetService.deleteBudget(uid: uid, id: budget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppI18n.t(context, en: 'Budget deleted', ar: 'تم حذف الميزانية'))),
      );
      await loadBudgets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(context, en: 'Could not delete this budget.', ar: 'تعذر حذف هذه الميزانية.'),
          ),
        ),
      );
    }
  }

  List<BudgetModel> categoryBudgets() {
    final list = <BudgetModel>[];
    for (final budget in budgetList) {
      if (!budget.isOverall) list.add(budget);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final calc = _calculator;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppI18n.t(context, en: 'Budget', ar: 'الميزانية'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F4D3D),
          ),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)))
            : errorMessage.isNotEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(errorMessage, textAlign: TextAlign.center),
                  ))
                : ResponsiveContent(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              children: [
                                if (calc.isOverAllocated)
                                  _OverAllocatedBanner(
                                    message: BudgetCalculator.overAllocatedBanner(
                                      calc.overAllocatedBy,
                                    ),
                                  ),
                                if (!calc.hasIncome) ...[
                                  _BlockedAddCard(
                                    messageEn: BudgetCalculator.addIncomeFirstMessage,
                                    messageAr: 'أضف دخلك أولاً',
                                    buttonEn: 'Add income',
                                    buttonAr: 'إضافة دخل',
                                    onPressed: openAddIncome,
                                  ),
                                  const SizedBox(height: 20),
                                ] else if (!calc.hasBalance) ...[
                                  _BlockedAddCard(
                                    messageEn: BudgetCalculator.addBalanceFirstMessage,
                                    messageAr: 'رصيدك الحالي 0. أضف دخلاً لزيادة الرصيد.',
                                    buttonEn: 'Add balance',
                                    buttonAr: 'إضافة رصيد',
                                    onPressed: openAddIncome,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                TotalBudgetCard(
                                  calculator: calc,
                                  onTap: openOverall,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  AppI18n.t(context, en: 'Category Budget', ar: 'ميزانية الفئات'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1F4D3D),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (budgetList.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32),
                                    child: Text(
                                      AppI18n.t(
                                        context,
                                        en: 'No budgets yet. Tap Add Budget.',
                                        ar: 'لا توجد ميزانيات بعد. اضغط إضافة ميزانية.',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                                    ),
                                  )
                                else if (categoryBudgets().isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      AppI18n.t(
                                        context,
                                        en: 'No category budgets yet.',
                                        ar: 'لا توجد ميزانيات فئات بعد.',
                                      ),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  )
                                else
                                  for (final budget in categoryBudgets())
                                    BudgetCard(
                                      budget: budget,
                                      needsAdjusting: calc.categoryNeedsAdjusting(
                                        budget.category,
                                      ),
                                      onTap: () => openDetails(budget),
                                      onEdit: () => openEditBudget(budget),
                                      onDelete: () => deleteBudget(budget),
                                    ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: (MediaQuery.sizeOf(context).width * 0.55)
                                      .clamp(280.0, 520.0),
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF27AE60).withValues(alpha: 0.32),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: openAddBudget,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF27AE60),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(28),
                                        ),
                                      ),
                                      child: Text(
                                        calc.canAddBudgets
                                            ? AppI18n.t(context, en: 'Add Budget', ar: 'إضافة ميزانية')
                                            : !calc.hasIncome
                                                ? AppI18n.t(context, en: 'Add income first', ar: 'أضف الدخل أولاً')
                                                : AppI18n.t(context, en: 'Add balance first', ar: 'أضف رصيداً أولاً'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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

class _OverAllocatedBanner extends StatelessWidget {
  const _OverAllocatedBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE24B4A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE24B4A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedAddCard extends StatelessWidget {
  const _BlockedAddCard({
    required this.messageEn,
    required this.messageAr,
    required this.buttonEn,
    required this.buttonAr,
    required this.onPressed,
  });

  final String messageEn;
  final String messageAr;
  final String buttonEn;
  final String buttonAr;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            AppI18n.t(context, en: messageEn, ar: messageAr),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF1F4D3D),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
            ),
            child: Text(AppI18n.t(context, en: buttonEn, ar: buttonAr)),
          ),
        ],
      ),
    );
  }
}
