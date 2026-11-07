import '../models/budget_models.dart';
import '../models/home_finance_data.dart';
import '../utils/finance_math.dart';
import 'finance_calculator.dart';
import 'money.dart';

enum BudgetLimitingFactor { income, balance }

class BudgetCalculator {
  const BudgetCalculator({
    required this.income,
    required this.totalBalance,
    required this.totalAllocated,
    required this.totalSpent,
    this.categoryLimits = const {},
    this.categorySpent = const {},
  });

  final int income;

  final int totalBalance;

  final int totalAllocated;

  final int totalSpent;

  final Map<String, int> categoryLimits;

  final Map<String, int> categorySpent;

  factory BudgetCalculator.fromMonth({
    required Iterable<FinanceTransaction> transactions,
    required Iterable<BudgetModel> budgets,
    required DateTime month,
    String? ignoreBudgetId,
  }) {
    final finance = FinanceCalculator.fromFinance(transactions);
    final limits = <String, int>{};
    var allocated = 0;
    for (final budget in budgets) {
      if (budget.id == ignoreBudgetId) continue;
      if (budget.isOverall) continue;
      if (budget.amountBaisa <= 0) continue;
      if (!sameMonth(budget.date ?? month, month)) continue;
      allocated += budget.amountBaisa;
      final id = mapToBudgetCategory(budget.category);
      if (id.isNotEmpty) {
        limits[id] = (limits[id] ?? 0) + budget.amountBaisa;
      }
    }
    return BudgetCalculator(
      income: finance.monthlyIncome(month),
      totalBalance: finance.availableBalance,
      totalAllocated: allocated,
      totalSpent: finance.monthlyExpense(month),
      categoryLimits: limits,
      categorySpent: finance.categorySpend(month),
    );
  }

  bool get hasIncome => income > 0;

  bool get hasBalance => totalBalance > 0;

  bool get canAddBudgets => hasIncome && hasBalance;

  int spentFor(String? categoryId) {
    final id = categoryId?.trim() ?? '';
    if (id.isEmpty) return 0;
    return categorySpent[id] ?? 0;
  }

  int limitFor(String? categoryId) {
    final id = categoryId?.trim() ?? '';
    if (id.isEmpty) return 0;
    return categoryLimits[id] ?? 0;
  }

  int remainingFor(String? categoryId) {
    final n = limitFor(categoryId) - spentFor(categoryId);
    return n < 0 ? 0 : n;
  }

  int get totalRemainingBudget {
    var n = 0;
    for (final id in categoryLimits.keys) {
      n += remainingFor(id);
    }
    return n;
  }

  bool get isOverIncome => totalAllocated > income;

  bool get isOverBalance => totalRemainingBudget > totalBalance;

  bool get isOverAllocated => isOverIncome || isOverBalance;

  int get overAllocatedBy {
    final byIncome = totalAllocated - income;
    final byBalance = totalRemainingBudget - totalBalance;
    var n = 0;
    if (byIncome > n) n = byIncome;
    if (byBalance > n) n = byBalance;
    return n;
  }

  int get unallocated {
    final byIncome = income - totalAllocated;
    final byBalance = totalBalance - totalRemainingBudget;
    final n = byIncome < byBalance ? byIncome : byBalance;
    return n < 0 ? 0 : n;
  }

  int get unallocatedRaw {
    final byIncome = income - totalAllocated;
    final byBalance = totalBalance - totalRemainingBudget;
    return byIncome < byBalance ? byIncome : byBalance;
  }

  int maxByIncomeFor(String? categoryId) {
    final current = limitFor(categoryId);
    final max = income - (totalAllocated - current);
    return max < 0 ? 0 : max;
  }

  int maxByBalanceFor(String? categoryId) {
    final currentRemaining = remainingFor(categoryId);
    final spent = spentFor(categoryId);
    final max =
        totalBalance - (totalRemainingBudget - currentRemaining) + spent;
    return max < 0 ? 0 : max;
  }

  int maxAllowedForCategory(String? categoryId) {
    if (!canAddBudgets && limitFor(categoryId) <= 0) return 0;
    final byIncome = maxByIncomeFor(categoryId);
    final byBalance = maxByBalanceFor(categoryId);
    final max = byIncome < byBalance ? byIncome : byBalance;
    return max < 0 ? 0 : max;
  }

  BudgetLimitingFactor limitingFactorFor(String? categoryId) {
    if (maxByBalanceFor(categoryId) < maxByIncomeFor(categoryId)) {
      return BudgetLimitingFactor.balance;
    }
    return BudgetLimitingFactor.income;
  }

  BudgetLimitingFactor get limitingFactor => limitingFactorFor(null);

  bool categoryNeedsAdjusting(String? categoryId) {
    if (!isOverAllocated) return false;
    if (isOverIncome) return limitFor(categoryId) > 0;
    return remainingFor(categoryId) > 0;
  }

  String? validateAmount({
    required int amountBaisa,
    String? categoryId,
  }) {
    final isAdd = limitFor(categoryId) <= 0;
    if (isAdd && !hasIncome) return addIncomeFirstMessage;
    if (isAdd && !hasBalance) return addBalanceFirstMessage;
    if (amountBaisa <= 0) return 'Amount must be greater than 0.';
    final max = maxAllowedForCategory(categoryId);
    if (amountBaisa > max) return exceedsMaxAllowedMessage(max);
    return null;
  }

  String constraintLabelFor(String? categoryId) {
    return limitingFactorFor(categoryId) == BudgetLimitingFactor.balance
        ? limitedByBalanceMessage
        : limitedByIncomeMessage;
  }

  bool needsIncomeReductionWarning(int newMonthlyIncomeBaisa) {
    return totalAllocated > newMonthlyIncomeBaisa;
  }

  bool needsBalanceReductionWarning(int newTotalBalanceBaisa) {
    return totalRemainingBudget > newTotalBalanceBaisa;
  }

  bool needsConstraintWarning({
    int? newMonthlyIncomeBaisa,
    int? newTotalBalanceBaisa,
  }) {
    return needsIncomeReductionWarning(newMonthlyIncomeBaisa ?? income) ||
        needsBalanceReductionWarning(newTotalBalanceBaisa ?? totalBalance);
  }

  static const addIncomeFirstMessage = 'Add your income first';
  static const addBalanceFirstMessage =
      'Your current balance is 0. Add income to increase your balance.';
  static const limitedByIncomeMessage = 'Limited by income';
  static const limitedByBalanceMessage = 'Limited by your current balance';

  static String availableToAllocateHint(int maxAllowedBaisa) =>
      'Available to allocate: ${Money.format(maxAllowedBaisa)}';

  static String exceedsMaxAllowedMessage(int maxAllowedBaisa) =>
      'Exceeds your limit. Max allowed: ${Money.format(maxAllowedBaisa)}';

  static String overAllocatedBanner(int overByBaisa) =>
      'Your budgets exceed your available balance/income by ${Money.format(overByBaisa)}. Please adjust them.';
}
