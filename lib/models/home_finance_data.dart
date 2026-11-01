enum BillKind { electricity, internet, generic }

enum TransactionKind { expense, income, saving }

class BillItem {
  const BillItem({
    required this.id,
    required this.name,
    required this.dueDate,
    this.kind = BillKind.generic,
  });

  final String id;
  final String name;
  final DateTime dueDate;
  final BillKind kind;
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
  // Budget category id for expenses (food, shopping, …). Null if not set.
  final String? category;
}

/// Wallet totals are stored in baisa (1 OMR = 1000 baisa).
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

  /// Empty wallet for a user who has not added any records.
  factory HomeFinanceData.empty() => const HomeFinanceData(
        totalBalance: 0,
        totalExpense: 0,
        totalIncome: 0,
        totalSaving: 0,
        bills: [],
        transactions: [],
      );

  /// Balance = income − expense − saving (available cash).
  factory HomeFinanceData.fromRecords({
    required List<FinanceTransaction> transactions,
    required List<BillItem> bills,
  }) {
    var income = 0;
    var expense = 0;
    var saving = 0;
    for (final tx in transactions) {
      switch (tx.kind) {
        case TransactionKind.income:
          income += tx.amountBaisa;
        case TransactionKind.expense:
          expense += tx.amountBaisa;
        case TransactionKind.saving:
          saving += tx.amountBaisa;
      }
    }
    final sortedTx = [...transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sortedBills = [...bills]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return HomeFinanceData(
      totalIncome: income,
      totalExpense: expense,
      totalSaving: saving,
      totalBalance: income - expense - saving,
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
