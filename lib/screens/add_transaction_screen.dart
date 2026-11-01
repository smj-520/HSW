import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../services/admin_services.dart';
import '../models/budget_models.dart';
import '../widgets/budget_widgets.dart';
import '../models/home_finance_data.dart';
import '../services/app_i18n.dart';
import '../services/finance_repository.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/home_widgets.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';

String? _sessionUid() {
  if (Firebase.apps.isEmpty) return null;
  return FirebaseAuth.instance.currentUser?.uid;
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, required this.kind});

  final TransactionKind kind;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;
  List<BillerModel> billerList = [];
  String? selectedBillerId;
  String? selectedBudgetCategory;

  @override
  void initState() {
    super.initState();
    if (widget.kind == TransactionKind.expense) {
      loadBillers();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  // Loads billers so an expense can be linked to one (this feeds the admin report).
  Future<void> loadBillers() async {
    try {
      final list = await BillerService().loadBillerList();
      if (!mounted) return;
      setState(() => billerList = list);
    } catch (_) {}
  }

  Color get _accent {
    switch (widget.kind) {
      case TransactionKind.expense:
        return AppColors.homeExpense;
      case TransactionKind.income:
        return AppColors.homeIncome;
      case TransactionKind.saving:
        return AppColors.homeSaving;
    }
  }

  Future<void> _save() async {
    final baisa = parseOmrToBaisa(_amount.text);
    if (baisa == null) {
      setState(() => _error = 'Enter an amount greater than 0');
      return;
    }
    final uid = _sessionUid();
    if (uid == null) {
      setState(() => _error = 'You must be signed in to save');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FinanceRepository().addTransaction(
        uid: uid,
        kind: widget.kind,
        amountBaisa: baisa,
        note: _note.text,
        category: widget.kind == TransactionKind.expense
            ? selectedBudgetCategory
            : null,
      );
      // If this expense is for a biller, also save a payment for the admin report.
      if (widget.kind == TransactionKind.expense && selectedBillerId != null) {
        String billerName = '';
        for (final biller in billerList) {
          if (biller.id == selectedBillerId) {
            billerName = biller.name;
            break;
          }
        }
        await ReportService().addPayment(
          uid: uid,
          billerId: selectedBillerId!,
          billerName: billerName,
          amountBaisa: baisa,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: _accent,
          content: Text('${widget.kind.addTitle} saved'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        title: Text(widget.kind.addTitle),
      ),
      body: ResponsiveContent(
      child: ListView(
        padding: EdgeInsets.all(responsivePagePaddingX(MediaQuery.sizeOf(context).width).clamp(16, 28)),
        children: [
          Text(
            AppI18n.t(context, en: 'Amount (OMR)', ar: 'المبلغ (ر.ع)'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: '0.000'),
          ),
          const SizedBox(height: 16),
          if (widget.kind == TransactionKind.expense) ...[
            Text(AppI18n.t(context, en: 'Budget category (optional)', ar: 'فئة الميزانية (اختياري)')),
            const SizedBox(height: 8),
            CategoryDropdown(
              selectedId: selectedBudgetCategory,
              includeNone: true,
              onChanged: _saving
                  ? (_) {}
                  : (id) => setState(() => selectedBudgetCategory = id),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.kind == TransactionKind.expense && billerList.isNotEmpty) ...[
            Text(
              AppI18n.t(
                context,
                en: 'Biller (optional, for the admin report)',
                ar: 'الجهة (اختياري، لتقرير المسؤول)',
              ),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedBillerId,
              hint: Text(AppI18n.t(context, en: 'None', ar: 'بدون')),
              items: [
                for (final biller in billerList)
                  DropdownMenuItem(value: biller.id, child: Text(biller.name)),
              ],
              onChanged: _saving
                  ? null
                  : (id) => setState(() => selectedBillerId = id),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _note,
            enabled: !_saving,
            decoration: InputDecoration(
              hintText: AppI18n.t(context, en: 'Note (optional)', ar: 'ملاحظة (اختياري)'),
              labelText: AppI18n.t(context, en: 'Note', ar: 'ملاحظة'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.homeExpense)),
          ],
          const SizedBox(height: 24),
          PrimaryActionButton(
            label: widget.kind.localizedAddTitle(context),
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      ),
    );
  }
}

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _name = TextEditingController();
  DateTime _due = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;
  String? _error;
  List<BillerModel> billerList = [];
  String? selectedBillerId;

  @override
  void initState() {
    super.initState();
    loadBillers();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  // Loads the same biller list the admin manages, so users see new names.
  Future<void> loadBillers() async {
    try {
      final list = await BillerService().loadBillerList();
      if (!mounted) return;
      setState(() => billerList = list);
    } catch (_) {}
  }

  // When the user picks a biller, we copy its name into the name box.
  void pickBiller(String? id) {
    setState(() => selectedBillerId = id);
    if (id == null) return;
    for (final biller in billerList) {
      if (biller.id == id) {
        _name.text = biller.name;
        break;
      }
    }
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a bill name');
      return;
    }
    final uid = _sessionUid();
    if (uid == null) {
      setState(() => _error = 'You must be signed in to save');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FinanceRepository().addBill(uid: uid, name: name, dueDate: _due);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Bill saved')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        title: const Text('Add bill'),
      ),
      body: ResponsiveContent(
      child: ListView(
        padding: EdgeInsets.all(responsivePagePaddingX(MediaQuery.sizeOf(context).width).clamp(16, 28)),
        children: [
          if (billerList.isNotEmpty) ...[
            const Text('Pick a biller'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedBillerId,
              hint: const Text('Choose from admin list'),
              items: [
                for (final biller in billerList)
                  DropdownMenuItem(
                    value: biller.id,
                    child: Text('${biller.name} (${biller.category})'),
                  ),
              ],
              onChanged: _saving ? null : pickBiller,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _name,
            enabled: !_saving,
            decoration: const InputDecoration(
              labelText: 'Bill name',
              hintText: 'Electricity, Internet, …',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due date'),
            subtitle: Text(
              '${_due.year}-${_due.month.toString().padLeft(2, '0')}-${_due.day.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _saving ? null : _pickDue,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.homeExpense)),
          ],
          const SizedBox(height: 24),
          PrimaryActionButton(
            label: 'Save bill',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      ),
    );
  }
}

class AddTransactionPickerSheet extends StatelessWidget {
  const AddTransactionPickerSheet({super.key, required this.onSelected});

  final ValueChanged<TransactionKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.homeExpense,
                child: Icon(Icons.remove, color: Colors.white),
              ),
              title: Text(AppI18n.t(context, en: 'Add Expense', ar: 'إضافة مصروف')),
              onTap: () => onSelected(TransactionKind.expense),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.homeIncome,
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: Text(AppI18n.t(context, en: 'Add Income', ar: 'إضافة دخل')),
              onTap: () => onSelected(TransactionKind.income),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF3A3A3A),
                child: Icon(Icons.savings_rounded, color: Colors.white),
              ),
              title: Text(AppI18n.t(context, en: 'Add Saving', ar: 'إضافة ادخار')),
              onTap: () => onSelected(TransactionKind.saving),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key, required this.data});

  final HomeFinanceData data;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (data.transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No transactions yet',
                  style: TextStyle(color: AppColors.homeMuted, fontSize: 15),
                ),
              )
            else ...[
              for (final tx in data.transactions) _txTile(tx),
            ],
          ],
        ),
      ),
    );
  }

  Widget _txTile(FinanceTransaction tx) {
    final Color color;
    final OmrSign sign;
    final String title;
    switch (tx.kind) {
      case TransactionKind.expense:
        color = AppColors.homeExpense;
        sign = OmrSign.minus;
        title = 'Expense';
      case TransactionKind.income:
        color = AppColors.homeIncome;
        sign = OmrSign.plus;
        title = 'Income';
      case TransactionKind.saving:
        color = AppColors.homeSaving;
        sign = OmrSign.plus;
        title = 'Saving';
    }
    final note = tx.note.trim();
    final categoryName = findBudgetCategory(tx.category)?.name;
    final subtitle = note.isNotEmpty
        ? note
        : (categoryName ?? title);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (categoryName != null && note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      color: AppColors.homeMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            formatOmr(tx.amountBaisa, sign: sign),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, required this.data});

  final HomeFinanceData data;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text('Balance ${formatOmr(data.totalBalance)}'),
              const SizedBox(height: 8),
              Text('Income ${formatOmr(data.totalIncome)}'),
              const SizedBox(height: 8),
              Text('Expense ${formatOmr(data.totalExpense)}'),
              const SizedBox(height: 8),
              Text('Saving ${formatOmr(data.totalSaving)}'),
            ],
          ),
        ),
      ),
    );
  }
}

class BillsListScreen extends StatelessWidget {
  const BillsListScreen({
    super.key,
    required this.bills,
    this.now,
    this.onAddBill,
  });

  final List<BillItem> bills;
  final DateTime? now;
  final VoidCallback? onAddBill;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        title: const Text('Bills Reminder'),
        actions: [
          if (onAddBill != null)
            IconButton(
              tooltip: 'Add bill',
              onPressed: onAddBill,
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: bills.isEmpty
          ? const Center(
              child: Text(
                'No bills yet',
                style: TextStyle(color: AppColors.homeMuted, fontSize: 15),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bills.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final bill = bills[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(formatBillDue(bill.dueDate, now: now)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.bills, this.now});

  final List<BillItem> bills;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        title: const Text('Notifications'),
      ),
      body: bills.isEmpty
          ? const Center(
              child: Text(
                'No bills yet',
                style: TextStyle(color: AppColors.homeMuted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final bill in bills)
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(bill.name),
                    subtitle: Text(formatBillDue(bill.dueDate, now: now)),
                  ),
              ],
            ),
    );
  }
}
