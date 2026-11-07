import 'package:firebase_database/firebase_database.dart';

import '../constants/categories.dart';
import '../core/budget_calculator.dart';
import '../models/budget_models.dart';
import '../models/home_finance_data.dart';
import '../utils/app_messages.dart';
import '../utils/finance_math.dart';
import 'finance_repository.dart';

class BudgetService {
  BudgetService({
    FirebaseDatabase? database,
    FinanceRepository? financeRepo,
  })  : _root = (database ?? FirebaseDatabase.instance).ref('budgets'),
        _financeRepo = financeRepo ?? FinanceRepository();

  final DatabaseReference _root;
  final FinanceRepository _financeRepo;

  Future<List<BudgetModel>> loadBudgetList(String uid) async {
    final snapshot = await _root.child(uid).get();
    final finance = await _safeFinance(uid);
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
      final date = DateTime.tryParse(row['date']?.toString() ?? '');
      final period = monthPeriod(date ?? DateTime.now());
      final totals = totalsForPeriod(finance.transactions, period);
      final used = isOverall
          ? totals.expense
          : expenseUsedForCategory(
              transactions: finance.transactions,
              period: period,
              budgetCategoryId: category,
            );
      budgetList.add(
        BudgetModel(
          id: key.toString(),
          amountBaisa: amountBaisa,
          usedAmountBaisa: used,
          category: isOverall ? null : category,
          date: date,
          note: row['note']?.toString() ?? '',
        ),
      );
    });
    return budgetList;
  }

  BudgetModel? findOverall(List<BudgetModel> budgetList, {DateTime? periodDate}) {
    BudgetModel? match;
    for (final budget in budgetList) {
      if (!budget.isOverall) continue;
      if (periodDate != null &&
          !sameMonth(budget.date ?? DateTime.now(), periodDate)) {
        continue;
      }
      match = budget;
      break;
    }
    return match;
  }

  bool categoryAlreadyHasBudget({
    required List<BudgetModel> budgetList,
    required String category,
    String? ignoreBudgetId,
    DateTime? periodDate,
  }) {
    final anchor = periodDate ?? DateTime.now();
    for (final budget in budgetList) {
      if (budget.id == ignoreBudgetId) continue;
      if (budget.category != category) continue;
      if (!sameMonth(budget.date ?? DateTime.now(), anchor)) continue;
      return true;
    }
    return false;
  }

  int sumBudgetsInPeriod(
    List<BudgetModel> budgetList, {
    String? ignoreBudgetId,
    DateTime? periodDate,
  }) {
    final anchor = periodDate ?? DateTime.now();
    var total = 0;
    for (final budget in budgetList) {
      if (budget.id == ignoreBudgetId) continue;
      if (!sameMonth(budget.date ?? DateTime.now(), anchor)) continue;
      total += budget.amountBaisa;
    }
    return total;
  }

  int sumCategoryBudgets(
    List<BudgetModel> budgetList, {
    String? ignoreBudgetId,
    DateTime? periodDate,
  }) {
    final anchor = periodDate ?? DateTime.now();
    var total = 0;
    for (final budget in budgetList) {
      if (budget.id == ignoreBudgetId) continue;
      if (budget.isOverall) continue;
      final budgetMonth = budget.date ?? DateTime.now();
      if (!sameMonth(budgetMonth, anchor)) continue;
      total += budget.amountBaisa;
    }
    return total;
  }

  Future<String?> addBudget({
    required String uid,
    required int amountBaisa,
    String? category,
    DateTime? date,
    String note = '',
  }) async {
    final error = await validateBudgetAmount(
      uid: uid,
      amountBaisa: amountBaisa,
      category: category,
      date: date,
    );
    if (error != null) return error;
    final key = budgetDocId(category);
    final existing = await _root.child(uid).child(key).get();
    if (existing.exists && category != null && category.trim().isNotEmpty) {
      return AppMessages.budgetExistsForCategory;
    }
    await _root.child(uid).child(key).set(_toMap(
          amountBaisa: amountBaisa,
          category: category,
          date: date,
          note: note,
        ));
    return null;
  }

  Future<String?> updateBudget({
    required String uid,
    required String id,
    required int amountBaisa,
    String? category,
    DateTime? date,
    String note = '',
  }) async {
    final error = await validateBudgetAmount(
      uid: uid,
      amountBaisa: amountBaisa,
      category: category,
      date: date,
      ignoreBudgetId: id,
    );
    if (error != null) return error;
    await _root.child(uid).child(id).update(_toMap(
          amountBaisa: amountBaisa,
          category: category,
          date: date,
          note: note,
        ));
    return null;
  }

  Future<void> deleteBudget({required String uid, required String id}) {
    return _root.child(uid).child(id).remove();
  }

  Stream<Object?> watchRaw(String uid) {
    return _root.child(uid).onValue.map((event) => event.snapshot.value);
  }

  Future<String?> upsertCategoryBudget({
    required String uid,
    required String category,
    required int amountBaisa,
    DateTime? date,
    String note = '',
  }) async {
    final cat = category.trim();
    if (cat.isEmpty) return AppMessages.selectCategory;
    final month = date ?? DateTime.now();
    final id = budgetDocId(cat);
    final existing = await loadOneBudget(uid: uid, id: id);
    if (existing != null && !existing.isOverall) {
      return updateBudget(
        uid: uid,
        id: existing.id,
        amountBaisa: amountBaisa,
        category: cat,
        date: DateTime(month.year, month.month),
        note: note,
      );
    }
    return addBudget(
      uid: uid,
      amountBaisa: amountBaisa,
      category: cat,
      date: DateTime(month.year, month.month),
      note: note,
    );
  }

  Map<String, int> categoryBudgetMap(List<BudgetModel> budgetList) {
    final map = <String, int>{};
    for (final budget in budgetList) {
      if (budget.isOverall) continue;
      final raw = (budget.category ?? '').trim();
      if (raw.isEmpty || budget.amountBaisa <= 0) continue;
      final id = normalizeExpenseCategoryId(raw);
      map[id] = (map[id] ?? 0) + budget.amountBaisa;
    }
    return map;
  }

  Future<BudgetModel?> loadOneBudget({
    required String uid,
    required String id,
  }) async {
    final budgetList = await loadBudgetList(uid);
    for (final budget in budgetList) {
      if (budget.id == id) return budget;
    }
    return null;
  }

  Future<String?> validateBudgetAmount({
    required String uid,
    required int amountBaisa,
    String? category,
    DateTime? date,
    String? ignoreBudgetId,
  }) async {
    if (amountBaisa <= 0) return AppMessages.amountGreaterThanZero;

    final anchor = date ?? DateTime.now();
    final finance = await _safeFinance(uid);
    final budgetList = await _loadBudgetRows(uid);
    final calculator = BudgetCalculator.fromMonth(
      transactions: finance.transactions,
      budgets: budgetList,
      month: anchor,
      ignoreBudgetId: ignoreBudgetId,
    );
    return calculator.validateAmount(
      amountBaisa: amountBaisa,
      categoryId: category,
    );
  }

  String? categoryExceedsOverallWarning({
    required List<BudgetModel> budgetList,
    required int amountBaisa,
    required String category,
    String? ignoreBudgetId,
    DateTime? periodDate,
  }) {
    final overall = findOverall(budgetList, periodDate: periodDate);
    if (overall == null) return null;
    final already = sumCategoryBudgets(
      budgetList,
      ignoreBudgetId: ignoreBudgetId,
      periodDate: periodDate,
    );
    if (already + amountBaisa > overall.amountBaisa) {
      return AppMessages.categoryBudgetsExceedOverall;
    }
    return null;
  }

  String? budgetBelowSpentWarning({
    required BudgetModel current,
    required int newAmountBaisa,
  }) {
    if (newAmountBaisa < current.usedAmountBaisa) {
      return AppMessages.budgetLowerThanSpending;
    }
    return null;
  }

  Future<BudgetLimitCheck> allocationHint({
    required String uid,
    String? category,
    DateTime? date,
    String? ignoreBudgetId,
  }) async {
    final anchor = date ?? DateTime.now();
    final finance = await _safeFinance(uid);
    final budgetList = await _loadBudgetRows(uid);
    final calculator = BudgetCalculator.fromMonth(
      transactions: finance.transactions,
      budgets: budgetList,
      month: anchor,
      ignoreBudgetId: ignoreBudgetId,
    );
    final max = calculator.maxAllowedForCategory(category);
    return BudgetLimitCheck(
      ok: calculator.canAddBudgets && max > 0,
      availableIncomeBaisa: max,
      alreadyAllocatedBaisa: calculator.totalAllocated,
      remainingBaisa: max,
    );
  }

  Future<HomeFinanceData> _safeFinance(String uid) async {
    try {
      return await _financeRepo.load(uid);
    } catch (_) {
      return HomeFinanceData.empty();
    }
  }

  Future<List<BudgetModel>> _loadBudgetRows(String uid) async {
    final snapshot = await _root.child(uid).get();
    final value = snapshot.value;
    if (value is! Map) return [];
    final budgetList = <BudgetModel>[];
    value.forEach((key, dynamic raw) {
      if (raw is! Map) return;
      final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
      final amountBaisa = _asInt(row['amountBaisa']);
      if (amountBaisa <= 0) return;
      final category = (row['category'] as String?)?.trim();
      budgetList.add(
        BudgetModel(
          id: key.toString(),
          amountBaisa: amountBaisa,
          usedAmountBaisa: 0,
          category: (category == null || category.isEmpty) ? null : category,
          date: DateTime.tryParse(row['date']?.toString() ?? ''),
          note: row['note']?.toString() ?? '',
        ),
      );
    });
    return budgetList;
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
