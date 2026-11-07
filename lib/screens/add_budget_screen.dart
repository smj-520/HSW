import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/budget_calculator.dart';
import '../models/home_finance_data.dart';
import '../services/app_i18n.dart';
import '../services/finance_repository.dart';
import '../utils/app_messages.dart';
import '../utils/budget_amount_helper.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';
import '../widgets/budget_widgets.dart';
import 'add_transaction_screen.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key, this.budget});

  final BudgetModel? budget;

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _budgetService = BudgetService();
  String? selectedCategoryId;
  DateTime? selectedDate;
  bool isLoading = false;
  bool attemptedSave = false;
  int availableIncomeBaisaValue = 0;
  bool hasIncome = true;
  bool hasBalance = true;
  String constraintHint = BudgetCalculator.limitedByIncomeMessage;

  bool get isEdit => widget.budget != null;

  @override
  void initState() {
    super.initState();
    final old = widget.budget;
    if (old != null) {
      _amount.text = (old.amountBaisa / 1000).toStringAsFixed(3);
      selectedCategoryId = old.category;
      selectedDate = old.date;
      _note.text = old.note;
    }
    _amount.addListener(() => setState(() {}));
    refreshAvailableIncome();
  }

  Future<void> refreshAvailableIncome() async {
    final uid = sessionUid();
    if (uid == null) return;
    try {
      final finance = await FinanceRepository().load(uid);
      final list = await _budgetService.loadBudgetList(uid);
      final calculator = BudgetCalculator.fromMonth(
        transactions: finance.transactions,
        budgets: list,
        month: selectedDate ?? DateTime.now(),
        ignoreBudgetId: isEdit ? null : widget.budget?.id,
      );
      if (!mounted) return;
      setState(() {
        hasIncome = calculator.hasIncome;
        hasBalance = calculator.hasBalance;
        availableIncomeBaisaValue = calculator.maxAllowedForCategory(
          selectedCategoryId,
        );
        constraintHint = calculator.constraintLabelFor(selectedCategoryId);
      });
    } catch (_) {}
  }

  BudgetAmountFieldState amountFieldState() {
    return budgetAmountFieldState(
      raw: _amount.text,
      availableIncomeBaisa: availableIncomeBaisaValue,
      attemptedSave: attemptedSave,
      constraintHint: constraintHint,
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String? sessionUid() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      await refreshAvailableIncome();
    }
  }

  Future<void> saveBudget() async {
    setState(() => attemptedSave = true);
    final field = amountFieldState();
    if (!field.canSave || field.enteredBaisa == null) return;
    final amountBaisa = field.enteredBaisa!;
    if (isEdit && widget.budget != null) {
      final spentWarn = _budgetService.budgetBelowSpentWarning(
        current: widget.budget!,
        newAmountBaisa: amountBaisa,
      );
      if (spentWarn != null) _showSnack(spentWarn);
    }
    final uid = sessionUid();
    if (uid == null) {
      _showSnack(AppI18n.t(context, en: 'You must be signed in.', ar: 'يجب تسجيل الدخول.'));
      return;
    }

    setState(() => isLoading = true);
    try {
      final budgetList = await _budgetService.loadBudgetList(uid);
      final category = selectedCategoryId;
      final note = _note.text.trim();

      String? saveError;
      if (category == null || category.isEmpty) {
        saveError = await _saveOverall(
          uid: uid,
          amountBaisa: amountBaisa,
          budgetList: budgetList,
          note: note,
        );
      } else {
        saveError = await _saveCategory(
          uid: uid,
          amountBaisa: amountBaisa,
          category: category,
          budgetList: budgetList,
          note: note,
        );
      }
      if (saveError != null) {
        if (mounted) setState(() => isLoading = false);
        _showSnack(saveError);
        return;
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(content: Text(AppI18n.t(context, en: 'Budget saved', ar: 'تم حفظ الميزانية'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnack(
        AppI18n.t(context, en: 'Could not save. Check Firebase rules.', ar: 'تعذر الحفظ. تحقق من قواعد Firebase.'),
      );
    }
  }

  Future<String?> _saveOverall({
    required String uid,
    required int amountBaisa,
    required List<BudgetModel> budgetList,
    required String note,
  }) async {
    final existing = _budgetService.findOverall(
      budgetList,
      periodDate: selectedDate ?? DateTime.now(),
    );
    if (isEdit && widget.budget != null) {
      return _budgetService.updateBudget(
        uid: uid,
        id: widget.budget!.id,
        amountBaisa: amountBaisa,
        category: null,
        date: selectedDate,
        note: note,
      );
    }
    if (existing != null) {
      return _budgetService.updateBudget(
        uid: uid,
        id: existing.id,
        amountBaisa: amountBaisa,
        category: null,
        date: selectedDate,
        note: note,
      );
    }
    return _budgetService.addBudget(
      uid: uid,
      amountBaisa: amountBaisa,
      category: null,
      date: selectedDate,
      note: note,
    );
  }

  Future<String?> _saveCategory({
    required String uid,
    required int amountBaisa,
    required String category,
    required List<BudgetModel> budgetList,
    required String note,
  }) async {
    final ignoreId = isEdit ? widget.budget?.id : null;
    final taken = _budgetService.categoryAlreadyHasBudget(
      budgetList: budgetList,
      category: category,
      ignoreBudgetId: ignoreId,
      periodDate: selectedDate ?? DateTime.now(),
    );
    if (taken) {
      return AppMessages.budgetExistsForCategory;
    }
    final exceed = _budgetService.categoryExceedsOverallWarning(
      budgetList: budgetList,
      amountBaisa: amountBaisa,
      category: category,
      ignoreBudgetId: ignoreId,
      periodDate: selectedDate ?? DateTime.now(),
    );
    if (exceed != null) {
      _showSnack(exceed);
    }

    if (isEdit && widget.budget != null) {
      return _budgetService.updateBudget(
        uid: uid,
        id: widget.budget!.id,
        amountBaisa: amountBaisa,
        category: category,
        date: selectedDate,
        note: note,
      );
    }
    return _budgetService.addBudget(
      uid: uid,
      amountBaisa: amountBaisa,
      category: category,
      date: selectedDate,
      note: note,
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static const _muted = Color(0xFF8A8F8A);
  static const _green = Color(0xFF27AE60);

  static const _teal = Color(0xFF26A69A);
  static const _sky = Color(0xFF42A5F5);
  static const _coral = Color(0xFFFF8A65);
  static const _lavender = Color(0xFF7E57C2);
  static const _amber = Color(0xFFF4C430);

  InputDecoration fieldLook({
    required bool tablet,
    required Color accent,
    String? hint,
    String? helper,
    String? error,
    Color? helperColor,
    Widget? prefix,
    String? counter,
  }) {
    const radius = BorderRadius.all(Radius.circular(18));
    final pad = tablet
        ? const EdgeInsets.symmetric(horizontal: 22, vertical: 22)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 18);
    final helperSize = tablet ? 14.0 : 13.0;
    final hintSize = tablet ? 18.0 : 16.0;
    return InputDecoration(
      filled: true,
      fillColor: Theme.of(context).cardColor,
      hintText: hint,
      helperText: error == null ? helper : null,
      helperMaxLines: 4,
      helperStyle: TextStyle(
        color: helperColor ?? _muted,
        fontSize: helperSize,
        height: 1.35,
      ),
      errorText: error,
      errorMaxLines: 3,
      errorStyle: TextStyle(
        color: const Color(0xFFE74C3C),
        fontSize: helperSize,
        height: 1.35,
      ),
      prefixIcon: prefix,
      prefixIconColor: accent,
      counterText: counter,
      counterStyle: TextStyle(color: _muted, fontSize: helperSize),
      hintStyle: TextStyle(color: _muted, fontSize: hintSize),
      contentPadding: pad,
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: accent.withValues(alpha: 0.28)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: accent.withValues(alpha: 0.28)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: accent.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: accent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFE74C3C)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1.8),
      ),
    );
  }

  Widget _label({
    required String text,
    required IconData icon,
    required Color color,
    required bool tablet,
    bool requiredMark = false,
  }) {
    final box = tablet ? 40.0 : 36.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: tablet ? 22 : 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: text,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: tablet ? 18 : 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  if (requiredMark)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Color(0xFFE74C3C),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tintWrap({required Color color, required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountUi = amountFieldState();
    final canSave = amountUi.canSave && !isLoading;
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final tablet = size.width >= 700 || size.shortestSide >= 600;
    final sidePad = (size.width * 0.04).clamp(12.0, 36.0);
    final gap = tablet ? 28.0 : 20.0;
    final fieldFont = tablet ? 18.0 : 16.0;
    final buttonH = tablet ? 66.0 : 56.0;

    if (!isEdit && (!hasIncome || !hasBalance) && !isLoading) {
      final incomeBlocked = !hasIncome;
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            AppI18n.t(context, en: 'Add Budget', ar: 'إضافة ميزانية'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppI18n.t(
                    context,
                    en: incomeBlocked
                        ? BudgetCalculator.addIncomeFirstMessage
                        : BudgetCalculator.addBalanceFirstMessage,
                    ar: incomeBlocked
                        ? 'أضف دخلك أولاً'
                        : 'رصيدك الحالي 0. أضف دخلاً لزيادة الرصيد.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddTransactionScreen(
                          kind: TransactionKind.income,
                        ),
                      ),
                    ).then((_) => refreshAvailableIncome());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    incomeBlocked
                        ? AppI18n.t(context, en: 'Add income', ar: 'إضافة دخل')
                        : AppI18n.t(context, en: 'Add balance', ar: 'إضافة رصيد'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: tablet ? 64 : kToolbarHeight,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface, size: tablet ? 26 : 24),
        title: Text(
          isEdit
              ? AppI18n.t(context, en: 'Edit Budget', ar: 'تعديل الميزانية')
              : AppI18n.t(context, en: 'Add Budget', ar: 'إضافة ميزانية'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: tablet ? 22 : 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(sidePad, tablet ? 16 : 12, sidePad, 28 + bottomInset),
          children: [
            _label(
              text: AppI18n.t(context, en: 'Amount', ar: 'المبلغ'),
              icon: Icons.payments_outlined,
              color: _green,
              tablet: tablet,
              requiredMark: true,
            ),
            _tintWrap(
              color: amountUi.helperIsError || amountUi.fieldError != null
                  ? const Color(0xFFE74C3C)
                  : _green,
              child: TextField(
                controller: _amount,
                enabled: !isLoading,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: fieldFont, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                decoration: fieldLook(
                  tablet: tablet,
                  accent: amountUi.helperIsError || amountUi.fieldError != null
                      ? const Color(0xFFE74C3C)
                      : _green,
                  hint: AppI18n.t(context, en: 'Enter amount', ar: 'أدخل المبلغ'),
                  error: amountUi.fieldError,
                  prefix: Icon(Icons.payments_outlined, size: tablet ? 26 : 22),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (amountUi.helperIsError && amountUi.constraintHint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  amountUi.constraintHint!,
                  style: TextStyle(
                    color: const Color(0xFFE74C3C),
                    fontSize: tablet ? 14 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Text(
              amountUi.helper,
              style: TextStyle(
                color: amountUi.helperIsError
                    ? const Color(0xFFE74C3C)
                    : _muted,
                fontSize: tablet ? 14 : 13,
                height: 1.35,
                fontWeight: amountUi.helperIsError
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            SizedBox(height: gap),
            _label(
              text: AppI18n.t(context, en: 'Category (optional)', ar: 'الفئة (اختياري)'),
              icon: Icons.category_outlined,
              color: _teal,
              tablet: tablet,
            ),
            _tintWrap(
              color: _teal,
              child: CategoryDropdown(
                large: true,
                selectedId: selectedCategoryId,
                onChanged: isLoading
                    ? (id) {}
                    : (id) {
                        setState(() => selectedCategoryId = id);
                        refreshAvailableIncome();
                      },
              ),
            ),
            SizedBox(height: gap),
            _label(
              text: AppI18n.t(context, en: 'Date (optional)', ar: 'التاريخ (اختياري)'),
              icon: Icons.calendar_month_outlined,
              color: _sky,
              tablet: tablet,
            ),
            _tintWrap(
              color: _lavender,
              child: InkWell(
                onTap: isLoading ? null : pickDate,
                borderRadius: BorderRadius.circular(18),
                child: InputDecorator(
                  decoration: fieldLook(
                    tablet: tablet,
                    accent: _sky,
                    hint: AppI18n.t(context, en: 'Select Date', ar: 'اختر التاريخ'),
                    prefix: Icon(Icons.calendar_month_outlined, size: tablet ? 26 : 22),
                  ),
                  child: Text(
                    selectedDate == null
                        ? AppI18n.t(context, en: 'Select Date', ar: 'اختر التاريخ')
                        : DateFormat('yyyy-MM-dd').format(selectedDate!),
                    style: TextStyle(
                      color: selectedDate == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: fieldFont,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: gap),
            _label(
              text: AppI18n.t(context, en: 'Note (optional)', ar: 'ملاحظة (اختياري)'),
              icon: Icons.sticky_note_2_outlined,
              color: _amber,
              tablet: tablet,
            ),
            _tintWrap(
              color: _coral,
              child: TextField(
                controller: _note,
                enabled: !isLoading,
                maxLength: 100,
                maxLines: tablet ? 7 : 5,
                minLines: tablet ? 5 : 4,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: fieldFont, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                decoration: fieldLook(
                  tablet: tablet,
                  accent: _amber,
                  hint: AppI18n.t(context, en: 'Add note...', ar: 'أضف ملاحظة...'),
                  helper: AppI18n.t(
                    context,
                    en: 'Add any note for this budget (optional)',
                    ar: 'أضف أي ملاحظة لهذه الميزانية (اختياري)',
                  ),
                  prefix: Icon(Icons.sticky_note_2_outlined, size: tablet ? 26 : 22),
                  counter: '${_note.text.length}/100',
                ),
              ),
            ),
            SizedBox(height: tablet ? 36 : 28),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: buttonH,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isLoading || canSave
                      ? null
                      : () => setState(() => attemptedSave = true),
                  child: ElevatedButton(
                  onPressed: canSave && !isLoading ? saveBudget : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: const Color(0xFFB7E4C7),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppI18n.t(context, en: 'Save Budget', ar: 'حفظ الميزانية'),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: tablet ? 19 : 16,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
