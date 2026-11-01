import '../models/budget_models.dart';
import '../models/transaction_model.dart';
import './transaction_service.dart';
import '../models/report_model.dart';

// Loads this user's transactions and turns them into weekly or monthly totals.
// Screens must not do this math themselves.
class FinanceReportService {
  FinanceReportService({TransactionService? transactionService})
      : _transactionService = transactionService ?? TransactionService();

  final TransactionService _transactionService;

  // Monday 00:00 of the week that contains [day].
  DateTime weekStart(DateTime day) {
    final local = DateTime(day.year, day.month, day.day);
    return local.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  // Sunday 23:59:59 of that same week.
  DateTime weekEnd(DateTime weekStartDate) {
    final start = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day);
    final sunday = start.add(const Duration(days: 6));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
  }

  // First day of the month.
  DateTime monthStart(DateTime day) {
    return DateTime(day.year, day.month, 1);
  }

  // Last moment of the month.
  DateTime monthEnd(DateTime day) {
    final firstNext = DateTime(day.year, day.month + 1, 1);
    return firstNext.subtract(const Duration(milliseconds: 1));
  }

  // True if this date is inside start..end (local calendar days).
  bool isInPeriod({
    required DateTime date,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final local = date.toLocal();
    return !local.isBefore(startDate) && !local.isAfter(endDate);
  }

  // Builds a weekly report for the week that contains [anchor].
  Future<ReportModel> buildWeeklyReport({
    required String uid,
    required DateTime anchor,
  }) {
    final start = weekStart(anchor);
    final end = weekEnd(start);
    return buildReport(
      uid: uid,
      startDate: start,
      endDate: end,
      isWeekly: true,
    );
  }

  // Builds a monthly report for the month that contains [anchor].
  Future<ReportModel> buildMonthlyReport({
    required String uid,
    required DateTime anchor,
  }) {
    return buildReport(
      uid: uid,
      startDate: monthStart(anchor),
      endDate: monthEnd(anchor),
      isWeekly: false,
    );
  }

  // Loads this user's rows, keeps those in the period, then adds up totals.
  Future<ReportModel> buildReport({
    required String uid,
    required DateTime startDate,
    required DateTime endDate,
    required bool isWeekly,
  }) async {
    final allRows = await _transactionService.loadTransactionList(uid);
    final rows = <TransactionModel>[];
    for (final tx in allRows) {
      if (isInPeriod(date: tx.date, startDate: startDate, endDate: endDate)) {
        rows.add(tx);
      }
    }
    if (rows.isEmpty) {
      return emptyReport(startDate: startDate, endDate: endDate, isWeekly: isWeekly);
    }

    var totalIncome = 0;
    var totalExpense = 0;
    var totalSaving = 0;
    for (final tx in rows) {
      if (tx.isIncome) totalIncome += tx.amountBaisa;
      if (tx.isExpense) totalExpense += tx.amountBaisa;
      if (tx.isSaving) totalSaving += tx.amountBaisa;
    }

    return ReportModel(
      startDate: startDate,
      endDate: endDate,
      isWeekly: isWeekly,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalSaving: totalSaving,
      balance: totalIncome - totalExpense,
      categoryTotals: categoryTotalsFrom(rows, totalExpense),
      transactions: rows,
    );
  }

  // Groups expenses by category. Percent = category amount / total expenses.
  List<CategoryTotal> categoryTotalsFrom(List<TransactionModel> rows, int totalExpense) {
    final sums = <String, int>{};
    for (final tx in rows) {
      if (!tx.isExpense) continue;
      final id = (tx.category == null || tx.category!.isEmpty) ? 'others' : tx.category!;
      sums[id] = (sums[id] ?? 0) + tx.amountBaisa;
    }
    final ids = sums.keys.toList();
    ids.sort((a, b) => (sums[b] ?? 0).compareTo(sums[a] ?? 0));
    final list = <CategoryTotal>[];
    for (final id in ids) {
      final amount = sums[id] ?? 0;
      list.add(
        CategoryTotal(
          id: id,
          name: findBudgetCategory(id)?.name ?? id,
          amountBaisa: amount,
          percent: totalExpense <= 0 ? 0 : amount / totalExpense,
        ),
      );
    }
    return list;
  }
}
