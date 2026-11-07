import '../core/finance_calculator.dart';

enum BillKind { electricity, internet, generic }

enum TransactionKind { expense, income, saving }

class BillItem {
  const BillItem({
    required this.id,
    required this.name,
    required this.dueDate,
    this.kind = BillKind.generic,
    this.amountBaisa = 0,
    this.status = 'unpaid',
    this.category,
    this.userId = '',
    this.billerId,
    this.note = '',
  });

  final String id;
  final String name;
  final DateTime dueDate;
  final BillKind kind;
  final int amountBaisa;
  final String status;
  final String? category;
  final String userId;
  final String? billerId;
  final String note;

  bool get isPaid => status == 'paid';
  bool get isUnpaid => !isPaid;
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.kind,
    required this.amountBaisa,
    required this.createdAt,
    this.note = '',
    this.category,
  });

  final String id;
  final TransactionKind kind;
  final int amountBaisa;
  final DateTime createdAt;
  final String note;
  final String? category;
}

class HomeFinanceData {
  const HomeFinanceData({
    required this.totalBalance,
    required this.totalExpense,
    required this.totalIncome,
    required this.totalSaving,
    required this.bills,
    this.transactions = const [],
  });

  final int totalBalance;
  final int totalExpense;
  final int totalIncome;
  final int totalSaving;
  final List<BillItem> bills;
  final List<FinanceTransaction> transactions;

  factory HomeFinanceData.empty() => const HomeFinanceData(
        totalBalance: 0,
        totalExpense: 0,
        totalIncome: 0,
        totalSaving: 0,
        bills: [],
        transactions: [],
      );

  factory HomeFinanceData.fromRecords({
    required List<FinanceTransaction> transactions,
    required List<BillItem> bills,
  }) {
    final calc = FinanceCalculator.fromFinance(transactions);
    final sortedTx = [...transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sortedBills = [...bills]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return HomeFinanceData(
      totalIncome: calc.totalIncome,
      totalExpense: calc.totalExpense,
      totalSaving: calc.totalSaving,
      totalBalance: calc.availableBalance,
      bills: sortedBills,
      transactions: sortedTx,
    );
  }
}

BillKind billKindFromName(String name) {
  final n = name.trim().toLowerCase();
  if (n.contains('electric')) return BillKind.electricity;
  if (n.contains('internet') || n.contains('wifi')) return BillKind.internet;
  return BillKind.generic;
}

BillKind billKindFromStorage(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'electricity':
      return BillKind.electricity;
    case 'internet':
      return BillKind.internet;
    default:
      return BillKind.generic;
  }
}

TransactionKind? transactionKindFromStorage(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'income':
      return TransactionKind.income;
    case 'expense':
      return TransactionKind.expense;
    case 'saving':
      return TransactionKind.saving;
    default:
      return null;
  }
}
