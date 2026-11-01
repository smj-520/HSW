import 'package:flutter_test/flutter_test.dart';

import 'package:cpp/models/budget_models.dart';

void main() {
  test('Budget remaining is limit minus used and can go negative', () {
    const under = BudgetModel(
      id: 'food',
      amountBaisa: 100000,
      usedAmountBaisa: 40000,
      category: 'food',
    );
    expect(under.remainingBaisa, 60000);
    expect(formatBudgetOmr(under.remainingBaisa), '60 OMR');

    const over = BudgetModel(
      id: 'overall',
      amountBaisa: 50000,
      usedAmountBaisa: 80000,
    );
    expect(over.isOverall, isTrue);
    expect(over.remainingBaisa, -30000);
  });
}
