import '../utils/app_messages.dart';

class MoneyParse {
  const MoneyParse.ok(this.baisa) : error = null;
  const MoneyParse.error(this.error) : baisa = null;

  final int? baisa;
  final String? error;

  bool get ok => error == null && baisa != null && baisa! > 0;
}

abstract final class Money {
  static const int baisaPerOmr = 1000;

  static MoneyParse omrToBaisa(String? raw) {
    if (raw == null) {
      return const MoneyParse.error(AppMessages.amountRequired);
    }
    final cleaned = raw.trim().replaceAll(',', '');
    if (cleaned.isEmpty) {
      return const MoneyParse.error(AppMessages.amountRequired);
    }
    if (cleaned.startsWith('-')) {
      return const MoneyParse.error(AppMessages.amountGreaterThanZero);
    }
    if (RegExp(r'[^0-9.]').hasMatch(cleaned)) {
      return const MoneyParse.error(AppMessages.onlyNumbers);
    }
    if (RegExp(r'\..*\.').hasMatch(cleaned)) {
      return const MoneyParse.error(AppMessages.onlyNumbers);
    }
    final parts = cleaned.split('.');
    final wholeRaw = parts[0].isEmpty ? '0' : parts[0];
    final fracRaw = parts.length > 1 ? parts[1] : '';
    if (fracRaw.length > 3) {
      return const MoneyParse.error(AppMessages.onlyNumbers);
    }
    final whole = int.tryParse(wholeRaw);
    if (whole == null) {
      return const MoneyParse.error(AppMessages.onlyNumbers);
    }
    var frac = 0;
    if (fracRaw.isNotEmpty) {
      final padded = fracRaw.padRight(3, '0');
      final parsed = int.tryParse(padded);
      if (parsed == null) {
        return const MoneyParse.error(AppMessages.onlyNumbers);
      }
      frac = parsed;
    }
    final baisa = whole * baisaPerOmr + frac;
    if (baisa <= 0) {
      return const MoneyParse.error(AppMessages.amountGreaterThanZero);
    }
    return MoneyParse.ok(baisa);
  }

  static String baisaToOmr(int baisa) {
    final n = baisa.abs();
    final whole = n ~/ baisaPerOmr;
    final frac = (n % baisaPerOmr).toString().padLeft(3, '0');
    final sign = baisa < 0 ? '-' : '';
    return '$sign$whole.$frac';
  }

  static String format(int baisa) => '${baisaToOmr(baisa)} OMR';
}
