import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../core/budget_calculator.dart';
import '../core/money.dart';
import '../models/home_finance_data.dart';
import '../services/app_i18n.dart';
import '../services/budget_service.dart';
import '../services/finance_repository.dart';
import '../utils/budget_amount_helper.dart';
import 'category_tile.dart';
import '../screens/add_transaction_screen.dart';

Future<bool> showSetCategoryBudgetSheet({
  required BuildContext context,
  required ExpenseCategory category,
  required int currentBudgetBaisa,
  DateTime? month,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SetCategoryBudgetSheet(
        category: category,
        currentBudgetBaisa: currentBudgetBaisa,
        month: month ?? DateTime.now(),
      );
    },
  );
  return saved == true;
}

class SetCategoryBudgetSheet extends StatefulWidget {
  const SetCategoryBudgetSheet({
    super.key,
    required this.category,
    required this.currentBudgetBaisa,
    required this.month,
  });

  final ExpenseCategory category;
  final int currentBudgetBaisa;
  final DateTime month;

  @override
  State<SetCategoryBudgetSheet> createState() => _SetCategoryBudgetSheetState();
}

class _SetCategoryBudgetSheetState extends State<SetCategoryBudgetSheet> {
  late final TextEditingController _amount;
  String? _error;
  bool _saving = false;
  bool _hasIncome = true;
  bool _hasBalance = true;
  int _maxAllowed = 0;
  String _constraintHint = BudgetCalculator.limitedByIncomeMessage;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.currentBudgetBaisa > 0
          ? Money.baisaToOmr(widget.currentBudgetBaisa)
          : '',
    );
    _amount.addListener(() => setState(() {}));
    _loadCeiling();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadCeiling() async {
    if (Firebase.apps.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final finance = await FinanceRepository().load(uid);
      final list = await BudgetService().loadBudgetList(uid);
      final calc = BudgetCalculator.fromMonth(
        transactions: finance.transactions,
        budgets: list,
        month: widget.month,
      );
      if (!mounted) return;
      setState(() {
        _hasIncome = calc.hasIncome;
        _hasBalance = calc.hasBalance;
        _maxAllowed = calc.maxAllowedForCategory(widget.category.id);
        _constraintHint = calc.constraintLabelFor(widget.category.id);
      });
    } catch (_) {}
  }

  BudgetAmountFieldState get _field {
    return budgetAmountFieldState(
      raw: _amount.text,
      availableIncomeBaisa: _maxAllowed,
      attemptedSave: _error != null,
      constraintHint: _constraintHint,
    );
  }

  Future<void> _save() async {
    final field = _field;
    if (!field.canSave || field.enteredBaisa == null) {
      setState(() => _error = field.fieldError ?? field.helper);
      return;
    }
    if (!_hasIncome) {
      setState(() => _error = BudgetCalculator.addIncomeFirstMessage);
      return;
    }
    if (!_hasBalance && widget.currentBudgetBaisa <= 0) {
      setState(() => _error = BudgetCalculator.addBalanceFirstMessage);
      return;
    }
    if (Firebase.apps.isEmpty) {
      setState(() => _error = 'You must be signed in.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'You must be signed in.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await BudgetService().upsertCategoryBudget(
      uid: uid,
      category: widget.category.id,
      amountBaisa: field.enteredBaisa!,
      date: widget.month,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final field = _field;
    final canAdd = _hasIncome && _hasBalance;
    final isEdit = widget.currentBudgetBaisa > 0;
    final canSave = field.canSave && !_saving && (canAdd || isEdit);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryTile(category: cat, size: 44),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppI18n.t(
                    context,
                    en: 'Monthly budget',
                    ar: 'الميزانية الشهرية',
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            cat.label(context),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (!canAdd && !isEdit) ...[
            const SizedBox(height: 16),
            Text(
              AppI18n.t(
                context,
                en: !_hasIncome
                    ? BudgetCalculator.addIncomeFirstMessage
                    : BudgetCalculator.addBalanceFirstMessage,
                ar: !_hasIncome
                    ? 'أضف دخلك أولاً'
                    : 'رصيدك الحالي 0. أضف دخلاً لزيادة الرصيد.',
              ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(
                      kind: TransactionKind.income,
                    ),
                  ),
                ).then((_) => _loadCeiling());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
              ),
              child: Text(
                !_hasIncome
                    ? AppI18n.t(context, en: 'Add income', ar: 'إضافة دخل')
                    : AppI18n.t(context, en: 'Add balance', ar: 'إضافة رصيد'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              BudgetCalculator.availableToAllocateHint(_maxAllowed),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (field.helperIsError && field.constraintHint != null) ...[
              const SizedBox(height: 4),
              Text(
                field.constraintHint!,
                style: const TextStyle(
                  color: Color(0xFFE74C3C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.000',
                labelText: AppI18n.t(context, en: 'Amount (OMR)', ar: 'المبلغ (ر.ع)'),
                errorText: field.fieldError ?? _error,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  disabledBackgroundColor: const Color(0xFFB7E4C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        AppI18n.t(context, en: 'Save budget', ar: 'حفظ الميزانية'),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
