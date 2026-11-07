import 'package:flutter/material.dart';

import '../services/app_i18n.dart';

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.en,
    required this.ar,
    required this.shortEn,
    required this.shortAr,
    required this.color,
  });

  final String id;
  final String en;
  final String ar;
  final String shortEn;
  final String shortAr;
  final Color color;

  String label(BuildContext context) => AppI18n.t(context, en: en, ar: ar);

  String shortLabel(BuildContext context) =>
      AppI18n.t(context, en: shortEn, ar: shortAr);
}

const List<ExpenseCategory> kExpenseCategories = [
  ExpenseCategory(
    id: 'hostel_fees',
    en: 'Hostel fees',
    ar: 'رسوم السكن',
    shortEn: 'Hostel fees',
    shortAr: 'رسوم السكن',
    color: Color(0xFF5B6CFF),
  ),
  ExpenseCategory(
    id: 'mess_food',
    en: 'Mess & food',
    ar: 'الأكل والكافتيريا',
    shortEn: 'Mess & food',
    shortAr: 'الأكل',
    color: Color(0xFFF25C5C),
  ),
  ExpenseCategory(
    id: 'laundry',
    en: 'Laundry',
    ar: 'المغسلة',
    shortEn: 'Laundry',
    shortAr: 'المغسلة',
    color: Color(0xFF1FA8E8),
  ),
  ExpenseCategory(
    id: 'transport',
    en: 'Transport (bus + taxi)',
    ar: 'المواصلات',
    shortEn: 'Transport',
    shortAr: 'المواصلات',
    color: Color(0xFFF59A1B),
  ),
  ExpenseCategory(
    id: 'study',
    en: 'Study & printing',
    ar: 'القرطاسية والطباعة',
    shortEn: 'Study',
    shortAr: 'الدراسة',
    color: Color(0xFF8B6BD6),
  ),
  ExpenseCategory(
    id: 'mobile',
    en: 'Mobile & internet',
    ar: 'الرصيد والإنترنت',
    shortEn: 'Mobile',
    shortAr: 'الرصيد',
    color: Color(0xFF1E9E8F),
  ),
  ExpenseCategory(
    id: 'health',
    en: 'Health',
    ar: 'الصحة',
    shortEn: 'Health',
    shortAr: 'الصحة',
    color: Color(0xFFE5484D),
  ),
  ExpenseCategory(
    id: 'personal_care',
    en: 'Personal care',
    ar: 'العناية الشخصية',
    shortEn: 'Personal care',
    shortAr: 'العناية',
    color: Color(0xFFE8559A),
  ),
  ExpenseCategory(
    id: 'entertainment',
    en: 'Entertainment',
    ar: 'الترفيه',
    shortEn: 'Fun',
    shortAr: 'الترفيه',
    color: Color(0xFFE0A100),
  ),
  ExpenseCategory(
    id: 'gifts_family',
    en: 'Gifts & family',
    ar: 'الهدايا والعائلة',
    shortEn: 'Gifts',
    shortAr: 'الهدايا',
    color: Color(0xFFB25FC9),
  ),
  ExpenseCategory(
    id: 'groceries',
    en: 'Groceries (room supplies)',
    ar: 'مقاضي الغرفة',
    shortEn: 'Groceries',
    shortAr: 'المقاضي',
    color: Color(0xFF4CAF50),
  ),
  ExpenseCategory(
    id: 'emergency',
    en: 'Emergency',
    ar: 'طوارئ',
    shortEn: 'Emergency',
    shortAr: 'طوارئ',
    color: Color(0xFFF2672D),
  ),
];

const Set<String> kExpenseCategoryIds = {
  'hostel_fees',
  'mess_food',
  'laundry',
  'transport',
  'study',
  'mobile',
  'health',
  'personal_care',
  'entertainment',
  'gifts_family',
  'groceries',
  'emergency',
};

const Map<String, Offset> kExpenseTileFractions = {
  'hostel_fees': Offset(90 / 340, 40 / 392),
  'mess_food': Offset(170 / 340, 40 / 392),
  'laundry': Offset(250 / 340, 40 / 392),
  'transport': Offset(306 / 340, 118 / 392),
  'study': Offset(306 / 340, 196 / 392),
  'mobile': Offset(306 / 340, 274 / 392),
  'health': Offset(250 / 340, 352 / 392),
  'personal_care': Offset(170 / 340, 352 / 392),
  'entertainment': Offset(90 / 340, 352 / 392),
  'gifts_family': Offset(34 / 340, 274 / 392),
  'groceries': Offset(34 / 340, 196 / 392),
  'emergency': Offset(34 / 340, 118 / 392),
};

ExpenseCategory? expenseCategoryById(String? id) {
  if (id == null) return null;
  for (final cat in kExpenseCategories) {
    if (cat.id == id) return cat;
  }
  return null;
}

String normalizeExpenseCategoryId(String? raw) {
  final id = (raw ?? '').trim().toLowerCase();
  if (kExpenseCategoryIds.contains(id)) return id;
  switch (id) {
    case 'house':
    case 'home':
      return 'hostel_fees';
    case 'food':
    case 'mess':
      return 'mess_food';
    case 'clothes':
      return 'laundry';
    case 'car':
    case 'taxi':
    case 'bus':
      return 'transport';
    case 'phone':
    case 'wifi':
    case 'internet':
      return 'mobile';
    case 'toiletries':
    case 'personal':
      return 'personal_care';
    case 'sports':
      return 'entertainment';
    case 'gifts':
    case 'family':
      return 'gifts_family';
    case 'shopping':
      return 'groceries';
    default:
      return 'emergency';
  }
}
