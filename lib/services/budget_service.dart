import 'package:firebase_database/firebase_database.dart';

import '../models/home_finance_data.dart';
import './finance_repository.dart';
import '../models/budget_models.dart';

// All budget database work lives here. Screens must not talk to Firebase themselves.
class BudgetService {
  BudgetService({
    FirebaseDatabase? database,
    FinanceRepository? financeRepo,
  })  : _root = (database ?? FirebaseDatabase.instance).ref('budgets'),
        _financeRepo = financeRepo ?? FinanceRepository();

  final DatabaseReference _root;
  final FinanceRepository _financeRepo;

  // Loads this user's budgets. Each user only sees their own list.
  Future<List<BudgetModel>> loadBudgetList(String uid) async {
    final snapshot = await _root.child(uid).get();
    final spend = await _spendFromExpenses(uid);
    final value = snapshot.value;
    if (value is! Map) return [];

    final budgetList = <BudgetModel>[];
    value.forEach((key, dynamic raw) {
      if (raw is! Map) return;
      final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
      final amountBaisa = _asInt(row['amountBaisa']);
      if (amountBaisa <= 0) return;
      final category = (row['category'] as String?)?.trim();
      final isOverall = category == null || category.isEmpty;
      budgetList.add(
        BudgetModel(
          id: key.toString(),
          amountBaisa: amountBaisa,
          // Overall used = all expenses. Category used = expenses tagged with that category.
          usedAmountBaisa: isOverall
              ? spend.overall
              : (spend.byCategory[category] ?? 0),
          category: isOverall ? null : category,
          date: DateTime.tryParse(row['date']?.toString() ?? ''),
          note: row['note']?.toString() ?? '',
        ),
      );
    });
    return budgetList;
  }

  // Finds the one overall budget, or null if the user has not set it.
  BudgetModel? findOverall(List<BudgetModel> budgetList) {
    for (final budget in budgetList) {
      if (budget.isOverall) return budget;
    }
    return null;
  }

  // True if this category already has a budget (used when adding, not when editing the same one).
  bool categoryAlreadyHasBudget({
    required List<BudgetModel> budgetList,
    required String category,
    String? ignoreBudgetId,
  }) {
    for (final budget in budgetList) {
      if (budget.id == ignoreBudgetId) continue;
      if (budget.category == category) return true;
    }
    return false;
  }

  // Adds up all category budgets (not the overall one).
  int sumCategoryBudgets(List<BudgetModel> budgetList, {String? ignoreBudgetId}) {
    var total = 0;
    for (final budget in budgetList) {
      if (budget.id == ignoreBudgetId) continue;
      if (!budget.isOverall) total += budget.amountBaisa;
    }
    return total;
  }

  // Saves a new overall or category budget.
  Future<void> addBudget({
    required String uid,
    required int amountBaisa,
    String? category,
    DateTime? date,
    String note = '',
  }) {
    return _root.child(uid).push().set(_toMap(
          amountBaisa: amountBaisa,
          category: category,
          date: date,
          note: note,
        ));
  }

  // Changes an existing budget. Does not create a new one.
  Future<void> updateBudget({
    required String uid,
    required String id,
    required int amountBaisa,
    String? category,
    DateTime? date,
    String note = '',
  }) {
    return _root.child(uid).child(id).update(_toMap(
          amountBaisa: amountBaisa,
          category: category,
          date: date,
          note: note,
        ));
  }

  // Removes one budget for this user.
  Future<void> deleteBudget({required String uid, required String id}) {
    return _root.child(uid).child(id).remove();
  }

  // Finds one budget by id after loading the list (so used amounts stay correct).
  Future<BudgetModel?> loadOneBudget({required String uid, required String id}) async {
    final budgetList = await loadBudgetList(uid);
    for (final budget in budgetList) {
      if (budget.id == id) return budget;
    }
    return null;
  }

  // Reads this user's expenses once: overall total + totals per budget category.
  Future<_ExpenseSpend> _spendFromExpenses(String uid) async {
    try {
      final data = await _financeRepo.load(uid);
      final byCategory = <String, int>{};
      for (final tx in data.transactions) {
        if (tx.kind != TransactionKind.expense) continue;
        final category = tx.category?.trim();
        if (category == null || category.isEmpty) continue;
        byCategory[category] = (byCategory[category] ?? 0) + tx.amountBaisa;
      }
      return _ExpenseSpend(overall: data.totalExpense, byCategory: byCategory);
    } catch (_) {
      return const _ExpenseSpend(overall: 0, byCategory: {});
    }
  }

  Map<String, Object?> _toMap({
    required int amountBaisa,
    String? category,
    DateTime? date,
    String note = '',
  }) {
    return {
      'amountBaisa': amountBaisa,
      'category': (category == null || category.isEmpty) ? null : category,
      'date': date?.toIso8601String(),
      'note': note.trim(),
      'usedAmountBaisa': 0,
    };
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// Tiny helper so we only load finance data one time.
class _ExpenseSpend {
  const _ExpenseSpend({required this.overall, required this.byCategory});

  final int overall;
  final Map<String, int> byCategory;
}
