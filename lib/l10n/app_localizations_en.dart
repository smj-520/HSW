// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get amountRequired => 'Amount is required.';

  @override
  String get amountGreaterThanZero => 'Amount must be greater than 0.';

  @override
  String get onlyNumbers => 'Only numbers are allowed.';

  @override
  String get invalidAmount => 'Invalid amount.';

  @override
  String get invalidAmountBudgetUnchanged =>
      'Invalid amount. Budget is not changed.';

  @override
  String get selectCategory => 'Please select a category.';

  @override
  String get allFieldsRequired => 'All fields are required.';

  @override
  String get dueDateRequired => 'Due date is required.';

  @override
  String get budgetExistsForCategory =>
      'A budget already exists for this category. Use Edit.';

  @override
  String get categoryBudgetsExceedOverall =>
      'category budgets exceed the overall budget';

  @override
  String get budgetLowerThanSpending =>
      'budget is lower than the current spending';

  @override
  String get noBudgetSet => 'no budget is set';

  @override
  String get insufficientBalance => 'insufficient balance';

  @override
  String get noBillsFound => 'No bills found.';

  @override
  String get noUnpaidBills => 'No unpaid bills.';

  @override
  String get noPaidBills => 'No paid bills.';

  @override
  String get noPaymentHistory => 'No payment history.';

  @override
  String get noDataThisWeek => 'No data available for this week.';

  @override
  String get noDataThisMonth => 'No data available for this month.';

  @override
  String get noDataToDownload => 'No data to download.';

  @override
  String get permissionRequired => 'Storage permission is required.';

  @override
  String get noChartData => 'No data';

  @override
  String get accountIsBlocked => 'account is blocked';

  @override
  String get billerAlreadyExists => 'Biller already exists.';

  @override
  String get nameIsRequired => 'Name is required.';

  @override
  String get userBlocked => 'User blocked.';

  @override
  String get userUnblocked => 'User unblocked.';
}
