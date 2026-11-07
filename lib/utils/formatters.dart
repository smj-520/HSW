import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/money.dart';
import '../services/app_i18n.dart';

enum OmrSign { none, plus, minus }

int? parseOmrToBaisa(String? raw) => Money.omrToBaisa(raw).baisa;

String formatOmr(int baisa, {OmrSign sign = OmrSign.none}) {
  final body = Money.format(baisa.abs());
  switch (sign) {
    case OmrSign.plus:
      return '+$body';
    case OmrSign.minus:
      return '-$body';
    case OmrSign.none:
      return baisa < 0 ? '-$body' : body;
  }
}

class BillDuePill {
  const BillDuePill(this.label, this.color);
  final String label;
  final Color color;
}

BillDuePill billDuePill(DateTime dueDate, {DateTime? now}) {
  final origin = now ?? DateTime.now();
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(origin.year, origin.month, origin.day);
  final days = due.difference(today).inDays;
  if (days < 0) {
    return BillDuePill(
      AppI18n.ts(en: 'Overdue', ar: 'متأخر'),
      const Color(0xFFE24B4A),
    );
  }
  if (days == 0) {
    return BillDuePill(
      AppI18n.ts(en: 'Today', ar: 'اليوم'),
      const Color(0xFFE0A100),
    );
  }
  if (days == 1) {
    return BillDuePill(
      AppI18n.ts(en: 'Tomorrow', ar: 'غداً'),
      const Color(0xFFE0A100),
    );
  }
  return BillDuePill(
    AppI18n.ts(en: 'in $days days', ar: 'خلال $days أيام'),
    const Color(0xFF2E9E5B),
  );
}

String formatBillDue(DateTime dueDate, {DateTime? now}) {
  final origin = now ?? DateTime.now();
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(origin.year, origin.month, origin.day);
  final days = due.difference(today).inDays;
  if (days == 0) {
    return AppI18n.ts(en: 'due today', ar: 'مستحق اليوم');
  }
  if (days == 1) {
    return AppI18n.ts(en: 'due tomorrow', ar: 'مستحق غداً');
  }
  if (days > 1) {
    return AppI18n.ts(en: 'due in $days days', ar: 'مستحق خلال $days أيام');
  }
  if (days == -1) {
    return AppI18n.ts(en: 'overdue yesterday', ar: 'متأخر منذ أمس');
  }
  final overdue = -days;
  return AppI18n.ts(
    en: 'overdue by $overdue days',
    ar: 'متأخر منذ $overdue أيام',
  );
}

String resolveFirstName({
  String? displayName,
  String? email,
  String fallback = 'there',
}) {
  final full = displayName?.trim() ?? '';
  if (full.isNotEmpty) {
    return full.split(RegExp(r'\s+')).first;
  }

  final mail = email?.trim() ?? '';
  final at = mail.indexOf('@');
  if (at > 0) {
    final local = mail.substring(0, at);
    if (local.isEmpty) return fallback;
    return local[0].toUpperCase() + local.substring(1);
  }
  return fallback;
}

class AppDateFormat {
  AppDateFormat._();

  static String formatIsoUtcForDisplay(BuildContext context, String? isoUtc) {
    if (isoUtc == null || isoUtc.isEmpty) return '';
    final parsed = DateTime.tryParse(isoUtc);
    if (parsed == null) return isoUtc;
    final local = parsed.toLocal();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final datePart = DateFormat.yMMMd(locale).format(local);
    final timePart = DateFormat.jm(locale).format(local);
    return '$datePart · $timePart';
  }
}
