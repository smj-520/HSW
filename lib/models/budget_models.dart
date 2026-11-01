import 'package:flutter/material.dart';

import '../services/app_i18n.dart';

// One budget the user saved. Amounts are in baisa (1000 baisa = 1 OMR).
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

  // True when this is the one overall limit (no category).
  bool get isOverall => category == null || category!.isEmpty;

  // How much is left. Can be negative if they spent too much.
  int get remainingBaisa => amountBaisa - usedAmountBaisa;
}

// Turns baisa into text like "60 OMR" for the Budget screens.
String formatBudgetOmr(int baisa) {
  return '${(baisa / 1000).round()} OMR';
}

// One item in the category dropdown. Easy to add more later.
class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;
}

// The five categories from the screenshot.
const List<BudgetCategory> budgetCategories = [
  BudgetCategory(id: 'food', name: 'Food', icon: Icons.fastfood_outlined),
  BudgetCategory(id: 'shopping', name: 'Shopping', icon: Icons.shopping_bag_outlined),
  BudgetCategory(id: 'home', name: 'Home', icon: Icons.home_outlined),
  BudgetCategory(id: 'wifi', name: 'wifi', icon: Icons.wifi),
  BudgetCategory(id: 'others', name: 'Others', icon: Icons.apps_outlined),
];

// Finds a category by its id. Returns null if not found.
BudgetCategory? findBudgetCategory(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final item in budgetCategories) {
    if (item.id == id) return item;
  }
  return null;
}

String localizedBudgetCategoryName(BuildContext context, String? id) {
  switch (id) {
    case 'food':
      return AppI18n.t(context, en: 'Food', ar: 'طعام');
    case 'shopping':
      return AppI18n.t(context, en: 'Shopping', ar: 'تسوق');
    case 'home':
      return AppI18n.t(context, en: 'Home', ar: 'المنزل');
    case 'wifi':
      return AppI18n.t(context, en: 'wifi', ar: 'واي فاي');
    case 'others':
      return AppI18n.t(context, en: 'Others', ar: 'أخرى');
    default:
      return AppI18n.t(context, en: 'Budget', ar: 'الميزانية');
  }
}
