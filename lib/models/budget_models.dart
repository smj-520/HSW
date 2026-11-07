import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../services/app_i18n.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.amountBaisa,
    required this.usedAmountBaisa,
    this.category,
    this.date,
    this.note = '',
  });

  final String id;
  final int amountBaisa;
  final int usedAmountBaisa;
  final String? category;
  final DateTime? date;
  final String note;

  bool get isOverall => category == null || category!.isEmpty;

  int get remainingBaisa => amountBaisa - usedAmountBaisa;
}

String formatBudgetOmr(int baisa) {
  return '${(baisa / 1000).round()} OMR';
}

class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

final List<BudgetCategory> budgetCategories = [
  for (final cat in kExpenseCategories) BudgetCategory(id: cat.id, name: cat.en),
];

int? budgetUsagePercent({required int spentBaisa, required int budgetBaisa}) {
  if (budgetBaisa <= 0) return null;
  return (spentBaisa * 100 + budgetBaisa ~/ 2) ~/ budgetBaisa;
}

Color budgetUsageColor(int percent) {
  if (percent > 100) return const Color(0xFFE24B4A);
  if (percent >= 80) return const Color(0xFFE0A100);
  return const Color(0xFF2E9E5B);
}

String budgetDocId(String? category) {
  final id = category?.trim() ?? '';
  return id.isEmpty ? 'overall' : id;
}

BudgetCategory? findBudgetCategory(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final item in budgetCategories) {
    if (item.id == id) return item;
  }
  return null;
}

String localizedBudgetCategoryName(BuildContext context, String? id) {
  final cat = expenseCategoryById(normalizeExpenseCategoryId(id));
  if (cat == null) {
    return AppI18n.t(context, en: 'Budget', ar: 'الميزانية');
  }
  return cat.label(context);
}
