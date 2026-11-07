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

const List<BillerCategoryOption> kBillerCategories = [
  BillerCategoryOption(id: 'hostel_fees', en: 'Hostel fees', ar: 'رسوم السكن'),
  BillerCategoryOption(id: 'mess_food', en: 'Mess & food', ar: 'الأكل والكافتيريا'),
  BillerCategoryOption(id: 'laundry', en: 'Laundry', ar: 'المغسلة'),
  BillerCategoryOption(id: 'transport', en: 'Transport (bus + taxi)', ar: 'المواصلات'),
  BillerCategoryOption(id: 'study', en: 'Study & printing', ar: 'القرطاسية والطباعة'),
  BillerCategoryOption(id: 'mobile', en: 'Mobile & internet', ar: 'الرصيد والإنترنت'),
  BillerCategoryOption(id: 'health', en: 'Health', ar: 'الصحة'),
  BillerCategoryOption(id: 'personal_care', en: 'Personal care', ar: 'العناية الشخصية'),
  BillerCategoryOption(id: 'entertainment', en: 'Entertainment', ar: 'الترفيه'),
  BillerCategoryOption(id: 'gifts_family', en: 'Gifts & family', ar: 'الهدايا والعائلة'),
  BillerCategoryOption(id: 'groceries', en: 'Groceries (room supplies)', ar: 'مقاضي الغرفة'),
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
  int? amountBaisa,
}) {
  if (name.trim().isEmpty) return 'Name is required';
  if (category == null || category.trim().isEmpty) {
    return 'Category is required';
  }
  if (!isAllowedBillerCategory(category)) {
    return 'Select a valid category';
  }
  return null;
}

String formatBillerOmrCap(int amountBaisa) {
  if (amountBaisa % 1000 == 0) {
    return (amountBaisa / 1000).toStringAsFixed(0);
  }
  return (amountBaisa / 1000).toStringAsFixed(3);
}

String billerCapExceededMessage(int maxBaisa) {
  return 'Amount cannot exceed ${formatBillerOmrCap(maxBaisa)} OMR for this biller';
}

bool exceedsBillerCap({required int amountBaisa, required int capBaisa}) {
  if (capBaisa <= 0 || amountBaisa <= 0) return false;
  if (amountBaisa <= capBaisa) return false;
  if (capBaisa < 1000 && amountBaisa <= capBaisa * 1000) return false;
  return true;
}

int displayBillerCapBaisa({required int amountBaisa, required int capBaisa}) {
  if (capBaisa <= 0) return amountBaisa;
  if (amountBaisa <= capBaisa) return capBaisa;
  if (capBaisa < 1000 && amountBaisa <= capBaisa * 1000) {
    return capBaisa * 1000;
  }
  if (capBaisa < 1000) return capBaisa * 1000;
  return capBaisa;
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
