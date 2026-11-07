import '../core/budget_calculator.dart';
import '../core/money.dart';

String formatOmr3(int baisa) => Money.baisaToOmr(baisa);

String availableIncomeHelper(int availableBaisa) =>
    BudgetCalculator.availableToAllocateHint(availableBaisa);

String remainingAfterBudgetHelper(int remainingBaisa) =>
    BudgetCalculator.availableToAllocateHint(remainingBaisa);

String exceedsAvailableIncomeHelper(int availableBaisa) =>
    BudgetCalculator.exceedsMaxAllowedMessage(availableBaisa);

class BudgetAmountFieldState {
  const BudgetAmountFieldState({
    this.fieldError,
    required this.helper,
    required this.helperIsError,
    required this.canSave,
    this.enteredBaisa,
    this.constraintHint,
  });

  final String? fieldError;
  final String helper;
  final bool helperIsError;
  final bool canSave;
  final int? enteredBaisa;
  final String? constraintHint;
}

BudgetAmountFieldState budgetAmountFieldState({
  required String raw,
  required int availableIncomeBaisa,
  required bool attemptedSave,
  String? constraintHint,
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return BudgetAmountFieldState(
      fieldError: attemptedSave ? 'Amount is required' : null,
      helper: availableIncomeHelper(availableIncomeBaisa),
      helperIsError: false,
      canSave: false,
    );
  }

  final parsed = Money.omrToBaisa(trimmed);
  if (!parsed.ok) {
    return BudgetAmountFieldState(
      fieldError: 'Amount must be greater than 0',
      helper: availableIncomeHelper(availableIncomeBaisa),
      helperIsError: false,
      canSave: false,
    );
  }

  final enteredBaisa = parsed.baisa!;
  if (enteredBaisa > availableIncomeBaisa) {
    return BudgetAmountFieldState(
      fieldError: exceedsAvailableIncomeHelper(availableIncomeBaisa),
      helper: availableIncomeHelper(availableIncomeBaisa),
      helperIsError: true,
      canSave: false,
      enteredBaisa: enteredBaisa,
      constraintHint: constraintHint,
    );
  }

  return BudgetAmountFieldState(
    helper: availableIncomeHelper(availableIncomeBaisa),
    helperIsError: false,
    canSave: true,
    enteredBaisa: enteredBaisa,
  );
}

int availableIncomeBaisa({
  required int totalIncomeBaisa,
  required int alreadyBudgetedBaisa,
}) {
  final left = totalIncomeBaisa - alreadyBudgetedBaisa;
  return left < 0 ? 0 : left;
}
