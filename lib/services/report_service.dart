import '../core/finance_calculator.dart';
import '../models/budget_models.dart';
import '../models/transaction_model.dart';
import '../utils/finance_math.dart' as math;
import './transaction_service.dart';
import '../models/report_model.dart';

class FinanceReportService {
  FinanceReportService({TransactionService? transactionService})
      : _transactionService = transactionService ?? TransactionService();

  final TransactionService _transactionService;

  DateTime weekStart(DateTime day) => math.weekStart(day);

  DateTime weekEnd(DateTime weekStartDate) => math.weekEnd(weekStartDate);

  DateTime monthStart(DateTime day) => math.monthStart(day);

  DateTime monthEnd(DateTime day) => math.monthEnd(day);

  bool isInPeriod({
    required DateTime date,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return math.isInPeriod(
      date,
      math.FinancePeriod(
        start: startDate,
        end: endDate,
        isWeekly: false,
      ),
    );
  }

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

    final calc = FinanceCalculator.fromModels(rows);
    final totalIncome = calc.totalIncome;
    final totalExpense = calc.totalExpense;
    final totalSaving = calc.totalSaving;

    return ReportModel(
      startDate: startDate,
      endDate: endDate,
      isWeekly: isWeekly,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalSaving: totalSaving,
      balance: calc.availableBalance,
      categoryTotals: categoryTotalsFrom(rows, totalExpense),
      transactions: rows,
    );
  }

  List<CategoryTotal> categoryTotalsFrom(List<TransactionModel> rows, int totalExpense) {
    final sums = <String, int>{};
    for (final tx in rows) {
      if (!tx.isExpense) continue;
      final id = math.mapToBudgetCategory(tx.category);
      sums[id] = (sums[id] ?? 0) + tx.amountBaisa;
    }
    final ids = sums.keys.toList();
    ids.sort((a, b) => (sums[b] ?? 0).compareTo(sums[a] ?? 0));
    final amounts = [for (final id in ids) sums[id] ?? 0];
    final percents = FinanceCalculator.largestRemainderPercents(amounts);
    final list = <CategoryTotal>[];
    for (var i = 0; i < ids.length; i++) {
      final amount = amounts[i];
      list.add(
        CategoryTotal(
          id: ids[i],
          name: findBudgetCategory(ids[i])?.name ?? ids[i],
          amountBaisa: amount,
          percent: percents[i] / 100,
        ),
      );
    }
    return list;
  }
}
