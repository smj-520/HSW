import 'finance_calculator.dart';
import 'money.dart';
import '../utils/app_messages.dart';

class ValidationResult {
  const ValidationResult.ok() : ok = true, message = null;
  const ValidationResult.error(this.message) : ok = false;

  final bool ok;
  final String? message;
}

class TransactionValidator {
  TransactionValidator(this.calc);

  final FinanceCalculator calc;

  static String exceedsAvailable(int availableBaisa) =>
      'Expense exceeds available balance (${Money.format(availableBaisa)})';

  static String savingExceedsAvailable(int availableBaisa) =>
      'Saving exceeds available balance (${Money.format(availableBaisa)})';

  static String withdrawalExceedsSaving(int totalSavingBaisa) =>
      'Saving withdrawal exceeds total saving (${Money.format(totalSavingBaisa)})';

  static String incomeDeleteBlocked(int availableBaisa) =>
      'Cannot remove this income; balance would become negative (${Money.format(availableBaisa)})';

  static String budgetsExceedIncome(int monthlyIncomeBaisa) =>
      'Category budgets plus saving goal exceed monthly income (${Money.format(monthlyIncomeBaisa)})';

  static ValidationResult againstBalance({
    required String kind,
    required int amountBaisa,
    required int availableBaisa,
    required int totalSavingBaisa,
    String? category,
    bool requireCategory = false,
  }) {
    if (requireCategory && (category == null || category.trim().isEmpty)) {
      return const ValidationResult.error(AppMessages.selectCategory);
    }
    if (amountBaisa <= 0) {
      return const ValidationResult.error(AppMessages.amountGreaterThanZero);
    }
    if (kind == 'expense' && amountBaisa > availableBaisa) {
      return ValidationResult.error(exceedsAvailable(availableBaisa));
    }
    if (kind == 'saving' && amountBaisa > availableBaisa) {
      return ValidationResult.error(savingExceedsAvailable(availableBaisa));
    }
    if (kind == 'saving_withdrawal' && amountBaisa > totalSavingBaisa) {
      return ValidationResult.error(withdrawalExceedsSaving(totalSavingBaisa));
    }
    return const ValidationResult.ok();
  }

  ValidationResult validateAdd({
    required String kind,
    required int amountBaisa,
    String? category,
    bool requireCategory = false,
  }) {
    return againstBalance(
      kind: kind,
      amountBaisa: amountBaisa,
      availableBaisa: calc.availableBalance,
      totalSavingBaisa: calc.totalSaving,
      category: category,
      requireCategory: requireCategory,
    );
  }

  ValidationResult validateEdit({
    required CalcTx old,
    required String kind,
    required int amountBaisa,
    String? category,
    bool requireCategory = false,
  }) {
    return TransactionValidator(calc.excluding(old.id)).validateAdd(
      kind: kind,
      amountBaisa: amountBaisa,
      category: category,
      requireCategory: requireCategory,
    );
  }

  ValidationResult validateDelete(CalcTx old) {
    if (!old.isIncome) return const ValidationResult.ok();
    final next = calc.availableBalance - old.amountBaisa;
    if (next < 0) {
      return ValidationResult.error(incomeDeleteBlocked(calc.availableBalance));
    }
    return const ValidationResult.ok();
  }

  ValidationResult validateBillPay(int amountBaisa) {
    return validateAdd(kind: 'expense', amountBaisa: amountBaisa);
  }

  ValidationResult validateBudgets({
    required int categoryBudgetsSum,
    required int savingGoal,
    required int monthlyIncome,
  }) {
    if (categoryBudgetsSum + savingGoal > monthlyIncome) {
      return ValidationResult.error(budgetsExceedIncome(monthlyIncome));
    }
    return const ValidationResult.ok();
  }
}
