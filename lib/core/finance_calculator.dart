import '../models/home_finance_data.dart';
import '../models/transaction_model.dart';

class CalcTx {
  const CalcTx({
    required this.id,
    required this.kind,
    required this.amountBaisa,
    required this.date,
    this.category,
  });

  final String id;
  final String kind;
  final int amountBaisa;
  final DateTime date;
  final String? category;

  bool get isIncome => kind == 'income';
  bool get isExpense => kind == 'expense';
  bool get isSavingDeposit => kind == 'saving';
  bool get isSavingWithdrawal => kind == 'saving_withdrawal';

  factory CalcTx.fromFinance(FinanceTransaction tx) {
    return CalcTx(
      id: tx.id,
      kind: tx.kind.name,
      amountBaisa: tx.amountBaisa,
      date: tx.createdAt,
      category: tx.category,
    );
  }

  factory CalcTx.fromModel(TransactionModel tx) {
    return CalcTx(
      id: tx.id,
      kind: tx.type,
      amountBaisa: tx.amountBaisa,
      date: tx.date,
      category: tx.category,
    );
  }
}

class FinanceCalculator {
  FinanceCalculator(this.transactions);

  factory FinanceCalculator.fromFinance(Iterable<FinanceTransaction> rows) {
    return FinanceCalculator([for (final tx in rows) CalcTx.fromFinance(tx)]);
  }

  factory FinanceCalculator.fromModels(Iterable<TransactionModel> rows) {
    return FinanceCalculator([for (final tx in rows) CalcTx.fromModel(tx)]);
  }

  final List<CalcTx> transactions;

  int get totalIncome {
    var n = 0;
    for (final tx in transactions) {
      if (tx.isIncome) n += tx.amountBaisa;
    }
    return n;
  }

  int get totalExpense {
    var n = 0;
    for (final tx in transactions) {
      if (tx.isExpense) n += tx.amountBaisa;
    }
    return n;
  }

  int get totalSaving {
    var deposits = 0;
    var withdrawals = 0;
    for (final tx in transactions) {
      if (tx.isSavingDeposit) deposits += tx.amountBaisa;
      if (tx.isSavingWithdrawal) withdrawals += tx.amountBaisa;
    }
    return deposits - withdrawals;
  }

  int get availableBalance => totalIncome - totalExpense - totalSaving;

  int monthlyIncome(DateTime month) => _sumMonth(month, (tx) => tx.isIncome);

  int monthlyExpense(DateTime month) => _sumMonth(month, (tx) => tx.isExpense);

  int monthlySaving(DateTime month) {
    var n = 0;
    for (final tx in transactions) {
      if (!_inMonth(tx.date, month)) continue;
      if (tx.isSavingDeposit) n += tx.amountBaisa;
      if (tx.isSavingWithdrawal) n -= tx.amountBaisa;
    }
    return n;
  }

  int incomeInRange(DateTime start, DateTime end) =>
      _sumRange(start, end, (tx) => tx.isIncome);

  int expenseInRange(DateTime start, DateTime end) =>
      _sumRange(start, end, (tx) => tx.isExpense);

  int savingInRange(DateTime start, DateTime end) {
    var n = 0;
    for (final tx in transactions) {
      if (!_inRange(tx.date, start, end)) continue;
      if (tx.isSavingDeposit) n += tx.amountBaisa;
      if (tx.isSavingWithdrawal) n -= tx.amountBaisa;
    }
    return n;
  }

  int carryOverBalance(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    var income = 0;
    var expense = 0;
    var saving = 0;
    for (final tx in transactions) {
      if (!_before(tx.date, start)) continue;
      if (tx.isIncome) income += tx.amountBaisa;
      if (tx.isExpense) expense += tx.amountBaisa;
      if (tx.isSavingDeposit) saving += tx.amountBaisa;
      if (tx.isSavingWithdrawal) saving -= tx.amountBaisa;
    }
    return income - expense - saving;
  }

  int categoryExpense(String category, DateTime month) {
    final id = _cat(category);
    var n = 0;
    for (final tx in transactions) {
      if (!tx.isExpense || !_inMonth(tx.date, month)) continue;
      if (_cat(tx.category) == id) n += tx.amountBaisa;
    }
    return n;
  }

  Map<String, int> categorySpend(DateTime month) {
    final map = <String, int>{};
    for (final tx in transactions) {
      if (!tx.isExpense || !_inMonth(tx.date, month)) continue;
      final id = _cat(tx.category);
      if (id.isEmpty) continue;
      map[id] = (map[id] ?? 0) + tx.amountBaisa;
    }
    return map;
  }

  int categoryPercent(String category, DateTime month) {
    final total = monthlyExpense(month);
    if (total <= 0) return 0;
    final spend = categorySpend(month);
    final id = _cat(category);
    if (!spend.containsKey(id)) spend[id] = 0;
    final ids = spend.keys.toList()..sort();
    final amounts = [for (final key in ids) spend[key]!];
    final percents = largestRemainderPercents(amounts);
    for (var i = 0; i < ids.length; i++) {
      if (ids[i] == id) return percents[i];
    }
    return 0;
  }

  static String _cat(String? raw) => (raw ?? '').trim().toLowerCase();

  FinanceCalculator excluding(String id) {
    return FinanceCalculator([
      for (final tx in transactions)
        if (tx.id != id) tx,
    ]);
  }

  static List<int> largestRemainderPercents(List<int> amounts) {
    var total = 0;
    for (final n in amounts) {
      total += n;
    }
    if (total <= 0) return List<int>.filled(amounts.length, 0);
    final floors = List<int>.filled(amounts.length, 0);
    final fracTimesTotal = List<int>.filled(amounts.length, 0);
    var used = 0;
    for (var i = 0; i < amounts.length; i++) {
      final prod = amounts[i] * 100;
      floors[i] = prod ~/ total;
      fracTimesTotal[i] = prod % total;
      used += floors[i];
    }
    var leftover = 100 - used;
    final order = List<int>.generate(amounts.length, (i) => i)
      ..sort((a, b) {
        final c = fracTimesTotal[b].compareTo(fracTimesTotal[a]);
        return c != 0 ? c : a.compareTo(b);
      });
    var i = 0;
    while (leftover > 0 && order.isNotEmpty) {
      floors[order[i % order.length]]++;
      leftover--;
      i++;
    }
    return floors;
  }

  int _sumMonth(DateTime month, bool Function(CalcTx tx) match) {
    var n = 0;
    for (final tx in transactions) {
      if (match(tx) && _inMonth(tx.date, month)) n += tx.amountBaisa;
    }
    return n;
  }

  int _sumRange(DateTime start, DateTime end, bool Function(CalcTx tx) match) {
    var n = 0;
    for (final tx in transactions) {
      if (match(tx) && _inRange(tx.date, start, end)) n += tx.amountBaisa;
    }
    return n;
  }

  static bool _inMonth(DateTime date, DateTime month) {
    final d = date.toLocal();
    return d.year == month.year && d.month == month.month;
  }

  static bool _before(DateTime date, DateTime start) {
    return date.toLocal().isBefore(start);
  }

  static bool _inRange(DateTime date, DateTime start, DateTime end) {
    final d = date.toLocal();
    return !d.isBefore(start) && !d.isAfter(end);
  }
}
