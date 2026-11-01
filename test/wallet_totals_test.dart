import 'package:flutter_test/flutter_test.dart';

import 'package:cpp/models/home_finance_data.dart';

void main() {
  test('Wallet balance is income minus expense minus saving', () {
    final empty = HomeFinanceData.empty();
    expect(empty.totalBalance, 0);
    expect(empty.transactions, isEmpty);
    expect(empty.bills, isEmpty);

    final data = HomeFinanceData.fromRecords(
      transactions: [
        FinanceTransaction(
          id: 'i1',
          kind: TransactionKind.income,
          amountBaisa: 500000,
          createdAt: DateTime(2026, 9, 1),
        ),
        FinanceTransaction(
          id: 'e1',
          kind: TransactionKind.expense,
          amountBaisa: 100000,
          createdAt: DateTime(2026, 9, 2),
        ),
        FinanceTransaction(
          id: 's1',
          kind: TransactionKind.saving,
          amountBaisa: 50000,
          createdAt: DateTime(2026, 9, 3),
        ),
      ],
      bills: const [],
    );

    expect(data.totalIncome, 500000);
    expect(data.totalExpense, 100000);
    expect(data.totalSaving, 50000);
    expect(data.totalBalance, 350000);
  });
}
