import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required.'**
  String get amountRequired;

  /// No description provided for @amountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0.'**
  String get amountGreaterThanZero;

  /// No description provided for @onlyNumbers.
  ///
  /// In en, this message translates to:
  /// **'Only numbers are allowed.'**
  String get onlyNumbers;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount.'**
  String get invalidAmount;

  /// No description provided for @invalidAmountBudgetUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount. Budget is not changed.'**
  String get invalidAmountBudgetUnchanged;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category.'**
  String get selectCategory;

  /// No description provided for @allFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required.'**
  String get allFieldsRequired;

  /// No description provided for @dueDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Due date is required.'**
  String get dueDateRequired;

  /// No description provided for @budgetExistsForCategory.
  ///
  /// In en, this message translates to:
  /// **'A budget already exists for this category. Use Edit.'**
  String get budgetExistsForCategory;

  /// No description provided for @categoryBudgetsExceedOverall.
  ///
  /// In en, this message translates to:
  /// **'category budgets exceed the overall budget'**
  String get categoryBudgetsExceedOverall;

  /// No description provided for @budgetLowerThanSpending.
  ///
  /// In en, this message translates to:
  /// **'budget is lower than the current spending'**
  String get budgetLowerThanSpending;

  /// No description provided for @noBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'no budget is set'**
  String get noBudgetSet;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'insufficient balance'**
  String get insufficientBalance;

  /// No description provided for @noBillsFound.
  ///
  /// In en, this message translates to:
  /// **'No bills found.'**
  String get noBillsFound;

  /// No description provided for @noUnpaidBills.
  ///
  /// In en, this message translates to:
  /// **'No unpaid bills.'**
  String get noUnpaidBills;

  /// No description provided for @noPaidBills.
  ///
  /// In en, this message translates to:
  /// **'No paid bills.'**
  String get noPaidBills;

  /// No description provided for @noPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'No payment history.'**
  String get noPaymentHistory;

  /// No description provided for @noDataThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No data available for this week.'**
  String get noDataThisWeek;

  /// No description provided for @noDataThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No data available for this month.'**
  String get noDataThisMonth;

  /// No description provided for @noDataToDownload.
  ///
  /// In en, this message translates to:
  /// **'No data to download.'**
  String get noDataToDownload;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required.'**
  String get permissionRequired;

  /// No description provided for @noChartData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noChartData;

  /// No description provided for @accountIsBlocked.
  ///
  /// In en, this message translates to:
  /// **'account is blocked'**
  String get accountIsBlocked;

  /// No description provided for @billerAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Biller already exists.'**
  String get billerAlreadyExists;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameIsRequired;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get userBlocked;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked.'**
  String get userUnblocked;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
