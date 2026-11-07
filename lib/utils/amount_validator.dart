import '../core/money.dart';
import 'app_messages.dart';

enum AmountFieldKind { money, overallBudget, editBudget }

class AmountParseResult {
  const AmountParseResult({this.baisa, this.error});

  final int? baisa;
  final String? error;

  bool get ok => error == null && baisa != null && baisa! > 0;
}

AmountParseResult parseAmountField(
  String? raw, {
  AmountFieldKind kind = AmountFieldKind.money,
}) {
  if (raw == null || raw.trim().isEmpty) {
    return const AmountParseResult(error: AppMessages.amountRequired);
  }
  final parsed = Money.omrToBaisa(raw);
  if (kind == AmountFieldKind.overallBudget && parsed.error != null) {
    if (raw.trim().startsWith('-')) {
      return const AmountParseResult(error: AppMessages.invalidAmount);
    }
  }
  if (kind == AmountFieldKind.editBudget && !parsed.ok) {
    return const AmountParseResult(
      error: AppMessages.invalidAmountBudgetUnchanged,
    );
  }
  if (!parsed.ok) {
    return AmountParseResult(error: parsed.error, baisa: parsed.baisa);
  }
  return AmountParseResult(baisa: parsed.baisa);
}

bool hasInsufficientBalance({
  required int balanceBaisa,
  required int amountBaisa,
}) {
  return amountBaisa > balanceBaisa;
}
