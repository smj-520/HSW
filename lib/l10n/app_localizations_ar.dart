// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get amountRequired => 'المبلغ مطلوب.';

  @override
  String get amountGreaterThanZero => 'يجب أن يكون المبلغ أكبر من 0.';

  @override
  String get onlyNumbers => 'يُسمح بالأرقام فقط.';

  @override
  String get invalidAmount => 'مبلغ غير صالح.';

  @override
  String get invalidAmountBudgetUnchanged =>
      'مبلغ غير صالح. لم يتم تغيير الميزانية.';

  @override
  String get selectCategory => 'يرجى اختيار فئة.';

  @override
  String get allFieldsRequired => 'جميع الحقول مطلوبة.';

  @override
  String get dueDateRequired => 'تاريخ الاستحقاق مطلوب.';

  @override
  String get budgetExistsForCategory =>
      'توجد ميزانية لهذه الفئة. استخدم تعديل.';

  @override
  String get categoryBudgetsExceedOverall =>
      'ميزانيات الفئات تتجاوز الميزانية الإجمالية';

  @override
  String get budgetLowerThanSpending => 'الميزانية أقل من الإنفاق الحالي';

  @override
  String get noBudgetSet => 'لا توجد ميزانية';

  @override
  String get insufficientBalance => 'رصيد غير كافٍ';

  @override
  String get noBillsFound => 'لا توجد فواتير.';

  @override
  String get noUnpaidBills => 'لا توجد فواتير غير مدفوعة.';

  @override
  String get noPaidBills => 'لا توجد فواتير مدفوعة.';

  @override
  String get noPaymentHistory => 'لا يوجد سجل مدفوعات.';

  @override
  String get noDataThisWeek => 'لا توجد بيانات لهذا الأسبوع.';

  @override
  String get noDataThisMonth => 'لا توجد بيانات لهذا الشهر.';

  @override
  String get noDataToDownload => 'لا توجد بيانات للتنزيل.';

  @override
  String get permissionRequired => 'يلزم إذن التخزين.';

  @override
  String get noChartData => 'لا توجد بيانات';

  @override
  String get accountIsBlocked => 'الحساب محظور';

  @override
  String get billerAlreadyExists => 'المفوتر موجود بالفعل.';

  @override
  String get nameIsRequired => 'الاسم مطلوب.';

  @override
  String get userBlocked => 'تم حظر المستخدم.';

  @override
  String get userUnblocked => 'تم إلغاء حظر المستخدم.';
}
