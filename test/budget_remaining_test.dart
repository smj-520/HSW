import 'package:flutter/material.dart';
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

  test('Budget usage percent and colors', () {
    expect(
      budgetUsagePercent(spentBaisa: 0, budgetBaisa: 0),
      isNull,
    );
    expect(
      budgetUsagePercent(spentBaisa: 40000, budgetBaisa: 100000),
      40,
    );
    expect(
      budgetUsagePercent(spentBaisa: 80000, budgetBaisa: 100000),
      80,
    );
    expect(
      budgetUsagePercent(spentBaisa: 120000, budgetBaisa: 100000),
      120,
    );
    expect(budgetUsageColor(40), const Color(0xFF2E9E5B));
    expect(budgetUsageColor(80), const Color(0xFFE0A100));
    expect(budgetUsageColor(101), const Color(0xFFE24B4A));
  });
}
