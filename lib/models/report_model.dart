import './transaction_model.dart';

// One expense group in a report (name + amount + share of total expenses).
class CategoryTotal {
  const CategoryTotal({
    required this.id,
    required this.name,
    required this.amountBaisa,
    required this.percent,
  });

  final String id;
  final String name;
  final int amountBaisa;
  // 0 to 1. Example: 0.4 means 40% of expenses.
  final double percent;
}

// Totals for one week or one month. Amounts are in baisa.
class ReportModel {
  const ReportModel({
    required this.startDate,
    required this.endDate,
    required this.isWeekly,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSaving,
    required this.balance,
    required this.categoryTotals,
    required this.transactions,
  });

  final DateTime startDate;
  final DateTime endDate;
  final bool isWeekly;
  final int totalIncome;
  final int totalExpense;
  final int totalSaving;
  final int balance;
  final List<CategoryTotal> categoryTotals;
  final List<TransactionModel> transactions;

  bool get hasData => transactions.isNotEmpty;
}

// Empty report for a period with no saved rows.
ReportModel emptyReport({
  required DateTime startDate,
  required DateTime endDate,
  required bool isWeekly,
}) {
  return ReportModel(
    startDate: startDate,
    endDate: endDate,
    isWeekly: isWeekly,
    totalIncome: 0,
    totalExpense: 0,
    totalSaving: 0,
    balance: 0,
    categoryTotals: const [],
    transactions: const [],
  );
}
