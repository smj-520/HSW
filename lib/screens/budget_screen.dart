import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';
import '../widgets/budget_widgets.dart';
import './add_budget_screen.dart';
import './budget_details_screen.dart';

// The main Budget page: pie chart, category list, and Add Budget button.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetService = BudgetService();
  List<BudgetModel> budgetList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  // The signed-in user's id, or null if nobody is logged in.
  String? sessionUid() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Downloads this user's budgets from Firebase.
  Future<void> loadBudgets() async {
    final uid = sessionUid();
    if (uid == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'You must be signed in.';
      });
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final list = await _budgetService.loadBudgetList(uid);
      if (!mounted) return;
      setState(() {
        budgetList = list;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not load budgets. Check Firebase rules.';
      });
    }
  }

  // Tap the pie: open overall details, or Add Budget if there is no overall yet.
  Future<void> openOverall() async {
    final overall = _budgetService.findOverall(budgetList);
    if (overall == null) {
      await openAddBudget();
      return;
    }
    await openDetails(overall);
  }

  // Opens the read-only details page, then reloads when we come back.
  Future<void> openDetails(BudgetModel budget) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BudgetDetailsScreen(budget: budget),
      ),
    );
    await loadBudgets();
  }

  // Opens Add Budget, then reloads when we come back.
  Future<void> openAddBudget() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
    );
    await loadBudgets();
  }

  // Opens the same form, already filled with this budget's old data.
  Future<void> openEditBudget(BudgetModel budget) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(budget: budget),
      ),
    );
    await loadBudgets();
  }

  // Asks first, then deletes this budget and refreshes the pie and list.
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

  // Only the category rows (the overall limit lives in the top card).
  List<BudgetModel> categoryBudgets() {
    final list = <BudgetModel>[];
    for (final budget in budgetList) {
      if (!budget.isOverall) list.add(budget);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F0),
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
                                TotalBudgetCard(
                                  overall: _budgetService.findOverall(budgetList),
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
                                        AppI18n.t(context, en: 'Add Budget', ar: 'إضافة ميزانية'),
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
