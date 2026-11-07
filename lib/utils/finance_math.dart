import '../constants/categories.dart';
import '../core/finance_calculator.dart';
import '../models/budget_models.dart';
import '../models/home_finance_data.dart';

List<int> largestRemainderPercents(List<int> amounts) {
  return FinanceCalculator.largestRemainderPercents(amounts);
}

class FinancePeriod {
  const FinancePeriod({
    required this.start,
    required this.end,
    required this.isWeekly,
  });

  final DateTime start;
  final DateTime end;
  final bool isWeekly;
}

DateTime monthStart(DateTime day) => DateTime(day.year, day.month, 1);

DateTime monthEnd(DateTime day) {
  final firstNext = DateTime(day.year, day.month + 1, 1);
  return firstNext.subtract(const Duration(milliseconds: 1));
}

DateTime weekStart(DateTime day) {
  final local = DateTime(day.year, day.month, day.day);
  return local.subtract(Duration(days: local.weekday - DateTime.monday));
}

DateTime weekEnd(DateTime weekStartDate) {
  final start = DateTime(
    weekStartDate.year,
    weekStartDate.month,
    weekStartDate.day,
  );
  final sunday = start.add(const Duration(days: 6));
  return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
}

FinancePeriod monthPeriod(DateTime day) => FinancePeriod(
      start: monthStart(day),
      end: monthEnd(day),
      isWeekly: false,
    );

FinancePeriod weekPeriod(DateTime day) {
  final start = weekStart(day);
  return FinancePeriod(start: start, end: weekEnd(start), isWeekly: true);
}

FinancePeriod periodForBudget({required DateTime day, required bool isWeekly}) {
  return isWeekly ? weekPeriod(day) : monthPeriod(day);
}

bool isInPeriod(DateTime date, FinancePeriod period) {
  final local = date.toLocal();
  return !local.isBefore(period.start) && !local.isAfter(period.end);
}

bool sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

String mapToBudgetCategory(String? raw) {
  return normalizeExpenseCategoryId(raw);
}

class PeriodTotals {
  const PeriodTotals({
    required this.income,
    required this.expense,
    required this.saving,
  });

  final int income;
  final int expense;
  final int saving;

  int get balance => income - expense - saving;
}

PeriodTotals totalsForPeriod(
  Iterable<FinanceTransaction> transactions,
  FinancePeriod period,
) {
  final calc = FinanceCalculator.fromFinance(transactions);
  return PeriodTotals(
    income: calc.incomeInRange(period.start, period.end),
    expense: calc.expenseInRange(period.start, period.end),
    saving: calc.savingInRange(period.start, period.end),
  );
}

int expenseUsedForCategory({
  required Iterable<FinanceTransaction> transactions,
  required FinancePeriod period,
  required String budgetCategoryId,
}) {
  var used = 0;
  for (final tx in transactions) {
    if (tx.kind != TransactionKind.expense) continue;
    if (!isInPeriod(tx.createdAt, period)) continue;
    final mapped = mapToBudgetCategory(tx.category);
    final raw = (tx.category ?? '').trim();
    if (mapped == budgetCategoryId || raw == budgetCategoryId) {
      used += tx.amountBaisa;
    }
  }
  return used;
}

class BudgetLimitCheck {
  const BudgetLimitCheck({
    required this.ok,
    this.message,
    this.availableIncomeBaisa = 0,
    this.alreadyAllocatedBaisa = 0,
    this.remainingBaisa = 0,
  });

  final bool ok;
  final String? message;
  final int availableIncomeBaisa;
  final int alreadyAllocatedBaisa;
  final int remainingBaisa;
}

BudgetLimitCheck checkBudgetAgainstIncome({
  required int requestedBaisa,
  required int incomeBaisa,
  required int alreadyAllocatedBaisa,
}) {
  if (requestedBaisa <= 0) {
    return const BudgetLimitCheck(
      ok: false,
      message: 'Enter an amount greater than 0',
    );
  }
  final remaining = incomeBaisa - alreadyAllocatedBaisa;
  if (requestedBaisa <= remaining && requestedBaisa <= incomeBaisa) {
    return BudgetLimitCheck(
      ok: true,
      availableIncomeBaisa: incomeBaisa,
      alreadyAllocatedBaisa: alreadyAllocatedBaisa,
      remainingBaisa: remaining,
    );
  }

  if (alreadyAllocatedBaisa <= 0) {
    return BudgetLimitCheck(
      ok: false,
      availableIncomeBaisa: incomeBaisa,
      alreadyAllocatedBaisa: alreadyAllocatedBaisa,
      remainingBaisa: remaining < 0 ? 0 : remaining,
      message:
          'Your budget cannot exceed your available income. Your current available income is ${formatBudgetOmr(incomeBaisa)}.',
    );
  }

  final canAllocate = remaining < 0 ? 0 : remaining;
  return BudgetLimitCheck(
    ok: false,
    availableIncomeBaisa: incomeBaisa,
    alreadyAllocatedBaisa: alreadyAllocatedBaisa,
    remainingBaisa: canAllocate,
    message:
        'Your available income is ${formatBudgetOmr(incomeBaisa)}. You have already allocated ${formatBudgetOmr(alreadyAllocatedBaisa)}. You can allocate only ${formatBudgetOmr(canAllocate)} more.',
  );
}
