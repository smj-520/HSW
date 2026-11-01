import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_i18n.dart';

enum OmrSign { none, plus, minus }

/// Parses a user-entered OMR amount (e.g. `500` or `500.000`) to baisa.
/// Returns null when empty or not a positive amount.
int? parseOmrToBaisa(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  final omr = double.tryParse(cleaned);
  if (omr == null || omr <= 0) return null;
  return (omr * 1000).round();
}

/// Formats baisa amounts as Omani rial with 3 decimal places, e.g. `450.000 OMR`.
String formatOmr(int baisa, {OmrSign sign = OmrSign.none}) {
  final body = '${(baisa.abs() / 1000).toStringAsFixed(3)} OMR';
  switch (sign) {
    case OmrSign.plus:
      return '+$body';
    case OmrSign.minus:
      return '-$body';
    case OmrSign.none:
      return body;
  }
}

/// Human-readable bill due copy from a calendar date.
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

/// First name from profile / session. Never a hardcoded person name.
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

/// Formats stored ISO-8601 UTC strings (e.g. from Realtime Database) for UI.
class AppDateFormat {
  AppDateFormat._();

  /// Short local date + 12h time with AM/PM (locale-aware, e.g. en / ar).
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
