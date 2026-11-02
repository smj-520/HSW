import 'package:flutter/material.dart';

import '../services/app_i18n.dart';

class BillerCategoryOption {
  const BillerCategoryOption({
    required this.id,
    required this.en,
    required this.ar,
  });

  final String id;
  final String en;
  final String ar;
}

/// Allowed biller expense types — same ids as the student expense wheel.
const List<BillerCategoryOption> kBillerCategories = [
  BillerCategoryOption(id: 'hostel_fees', en: 'Hostel fees', ar: 'رسوم السكن'),
  BillerCategoryOption(id: 'mess_food', en: 'Mess', ar: 'الطعام'),
  BillerCategoryOption(id: 'laundry', en: 'Laundry', ar: 'غسيل'),
  BillerCategoryOption(id: 'transport', en: 'Transport', ar: 'مواصلات'),
  BillerCategoryOption(id: 'study', en: 'Study', ar: 'دراسة'),
  BillerCategoryOption(id: 'mobile', en: 'Mobile', ar: 'جوال'),
  BillerCategoryOption(id: 'health', en: 'Health', ar: 'صحة'),
  BillerCategoryOption(id: 'personal_care', en: 'Personal care', ar: 'عناية شخصية'),
  BillerCategoryOption(id: 'entertainment', en: 'Entertainment', ar: 'ترفيه'),
  BillerCategoryOption(id: 'gifts_family', en: 'Gifts', ar: 'هدايا'),
  BillerCategoryOption(id: 'groceries', en: 'Groceries', ar: 'بقالة'),
  BillerCategoryOption(id: 'emergency', en: 'Emergency', ar: 'طوارئ'),
];

const Set<String> kAllowedBillerCategoryIds = {
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

bool isAllowedBillerCategory(String? category) {
  final id = resolveBillerCategoryId(category);
  return id != null && kAllowedBillerCategoryIds.contains(id);
}

String? resolveBillerCategoryId(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  for (final option in kBillerCategories) {
    if (option.id == value) return option.id;
    if (option.en.toLowerCase() == value.toLowerCase()) return option.id;
  }
  return null;
}

String? validateBillerFields({
  required String name,
  required String? category,
  required String accountNumber,
}) {
  if (name.trim().isEmpty) return 'Name is required';
  if (category == null || category.trim().isEmpty) {
    return 'Category is required';
  }
  if (!isAllowedBillerCategory(category)) {
    return 'Select a valid category';
  }
  if (accountNumber.trim().isEmpty) return 'Account number is required';
  return null;
}

String localizedBillerCategory(BuildContext context, String? raw) {
  final id = resolveBillerCategoryId(raw);
  if (id == null) return (raw ?? '').trim();
  for (final option in kBillerCategories) {
    if (option.id == id) {
      return AppI18n.t(context, en: option.en, ar: option.ar);
    }
  }
  return (raw ?? '').trim();
}
