import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../constants/categories.dart';
import '../core/money.dart';
import '../core/transaction_validator.dart';
import '../services/app_i18n.dart';
import 'category_tile.dart';

class AddExpenseResult {
  const AddExpenseResult({
    required this.amountBaisa,
    required this.note,
    required this.date,
  });

  final int amountBaisa;
  final String note;
  final DateTime date;
}

Future<AddExpenseResult?> showAddExpenseSheet({
  required BuildContext context,
  required ExpenseCategory category,
  DateTime? initialDate,
  int availableBaisa = 0,
}) {
  return showModalBottomSheet<AddExpenseResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return AddExpenseSheet(
        category: category,
        initialDate: initialDate ?? DateTime.now(),
        availableBaisa: availableBaisa,
      );
    },
  );
}

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({
    super.key,
    required this.category,
    required this.initialDate,
    this.availableBaisa = 0,
  });

  final ExpenseCategory category;
  final DateTime initialDate;
  final int availableBaisa;

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  String _digits = '';
  final _note = TextEditingController();
  late DateTime _date;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate;
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int? get _baisa => Money.omrToBaisa(_digits).baisa;

  void _key(String value) {
    setState(() {
      _error = null;
      if (value == 'back') {
        if (_digits.isNotEmpty) {
          _digits = _digits.substring(0, _digits.length - 1);
        }
        return;
      }
      if (value == '.') {
        if (_digits.contains('.')) return;
        _digits = _digits.isEmpty ? '0.' : '$_digits.';
        return;
      }
      if (_digits.contains('.')) {
        final frac = _digits.split('.')[1];
        if (frac.length >= 3) return;
      }
      if (_digits == '0') {
        _digits = value;
        return;
      }
      _digits = '$_digits$value';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final baisa = _baisa;
    if (baisa == null) {
      setState(() {
        _error = AppI18n.t(context, en: 'Amount is required', ar: 'المبلغ مطلوب');
      });
      return;
    }
    final check = TransactionValidator.againstBalance(
      kind: 'expense',
      amountBaisa: baisa,
      availableBaisa: widget.availableBaisa,
      totalSavingBaisa: 0,
    );
    if (!check.ok) {
      setState(() => _error = check.message);
      return;
    }
    Navigator.of(context).pop(
      AddExpenseResult(
        amountBaisa: baisa,
        note: _note.text.trim(),
        date: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final display = _digits.isEmpty ? '0.000' : _digits;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CategoryTile(category: cat, size: 44),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  cat.label(context),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$display OMR',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: cat.color,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFE24B4A), fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              hintText: AppI18n.t(
                context,
                en: 'Note (optional)',
                ar: 'ملاحظة (اختياري)',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(DateFormat('yyyy-MM-dd').format(_date)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          _Keypad(color: cat.color, onKey: _key),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: cat.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppI18n.t(context, en: 'Save', ar: 'حفظ'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.color, required this.onKey});

  final Color color;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', 'back'],
    ];
    return Column(
      children: [
        for (final row in keys)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onKey(key),
                        child: SizedBox(
                          height: 48,
                          child: Center(
                            child: key == 'back'
                                ? Icon(Icons.backspace_outlined, color: color)
                                : Text(
                                    key,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
