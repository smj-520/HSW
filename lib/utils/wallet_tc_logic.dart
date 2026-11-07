import '../core/transaction_validator.dart';
import '../models/bill_model.dart';
import '../models/budget_models.dart';
import '../models/home_finance_data.dart';
import 'app_messages.dart';
import 'finance_math.dart';

class ExpenseSlice {
  const ExpenseSlice({
    required this.categoryId,
    required this.amountBaisa,
    required this.percent,
  });

  final String categoryId;
  final int amountBaisa;
  final int percent;
}

int remainingBudgetBaisa({required int amountBaisa, required int usedBaisa}) {
  final left = amountBaisa - usedBaisa;
  return left < 0 ? 0 : left;
}

String? noBudgetMessage(BudgetModel? budget) {
  if (budget == null) return AppMessages.noBudgetSet;
  return null;
}

const Object _omitBillCategory = Object();

String? addBillFieldError({
  required String name,
  required String amountRaw,
  required DateTime? dueDate,
  Object? category = _omitBillCategory,
}) {
  final missingName = name.trim().isEmpty;
  final missingAmount = amountRaw.trim().isEmpty;
  final missingDue = dueDate == null;
  final checkCategory = !identical(category, _omitBillCategory);
  final missingCategory = checkCategory &&
      (category == null || category.toString().trim().isEmpty);
  if (missingDue && !missingName && !missingAmount && !missingCategory) {
    return AppMessages.dueDateRequired;
  }
  if (missingCategory && !missingName && !missingAmount && !missingDue) {
    return AppMessages.selectCategory;
  }
  if (missingName || missingAmount || missingDue || missingCategory) {
    return AppMessages.allFieldsRequired;
  }
  return null;
}

String billsEmptyMessage({
  required String search,
  required bool showUnpaid,
  required List<BillModel> allBills,
  required List<BillModel> visibleBills,
}) {
  final q = search.trim();
  if (q.isNotEmpty && visibleBills.isEmpty) return AppMessages.noBillsFound;
  if (showUnpaid) {
    return visibleBills.isEmpty ? AppMessages.noUnpaidBills : '';
  }
  if (allBills.every((b) => b.isUnpaid) && visibleBills.isEmpty) {
    return AppMessages.noPaymentHistory;
  }
  return visibleBills.isEmpty ? AppMessages.noPaidBills : '';
}

String? payBillError({
  required int balanceBaisa,
  required BillModel bill,
}) {
  if (bill.isPaid) return 'This bill is already paid.';
  final result = TransactionValidator.againstBalance(
    kind: 'expense',
    amountBaisa: bill.amountBaisa,
    availableBaisa: balanceBaisa,
    totalSavingBaisa: 0,
  );
  return result.ok ? null : result.message;
}

String? moneyMoveError({
  required TransactionKind kind,
  required int amountBaisa,
  required int balanceBaisa,
  required String? category,
  required bool requireCategory,
}) {
  final result = TransactionValidator.againstBalance(
    kind: kind.name,
    amountBaisa: amountBaisa,
    availableBaisa: balanceBaisa,
    totalSavingBaisa: 0,
    category: category,
    requireCategory: requireCategory,
  );
  return result.ok ? null : result.message;
}

String emptyReportMessage({required bool isWeekly, required bool hasData}) {
  if (hasData) return '';
  return isWeekly ? AppMessages.noDataThisWeek : AppMessages.noDataThisMonth;
}

String? downloadReportError({
  required bool hasData,
  required bool storageAllowed,
}) {
  if (!hasData) return AppMessages.noDataToDownload;
  if (!storageAllowed) return AppMessages.permissionRequired;
  return null;
}

List<ExpenseSlice> homeExpenseSlices(List<FinanceTransaction> transactions) {
  final map = <String, int>{};
  for (final tx in transactions) {
    if (tx.kind != TransactionKind.expense || tx.amountBaisa <= 0) continue;
    final id = (tx.category ?? '').trim().isEmpty
        ? 'others'
        : mapToBudgetCategory(tx.category);
    map[id] = (map[id] ?? 0) + tx.amountBaisa;
  }
  if (map.isEmpty) return const [];
  final ids = map.keys.toList()..sort();
  final amounts = [for (final id in ids) map[id]!];
  final percents = largestRemainderPercents(amounts);
  return [
    for (var i = 0; i < ids.length; i++)
      ExpenseSlice(
        categoryId: ids[i],
        amountBaisa: amounts[i],
        percent: percents[i],
      ),
  ];
}

int homeChartPercentSum(List<ExpenseSlice> slices) =>
    slices.fold<int>(0, (sum, s) => sum + s.percent);
