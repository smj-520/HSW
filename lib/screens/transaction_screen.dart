import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_i18n.dart';
import '../services/app_settings_controller.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/transaction_widgets.dart';

// Transaction tab: All / Income / Expense / Saving, grouped by month.
class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {
  final _transactionService = TransactionService();
  late TabController tabController;
  List<TransactionModel> transactionList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) setState(() {});
    });
    loadTransactions();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  String? sessionUid() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Downloads this user's transactions. Newest already first from the service.
  Future<void> loadTransactions() async {
    final uid = sessionUid();
    if (uid == null) {
      setState(() {
        isLoading = false;
        errorMessage = AppI18n.ts(en: 'You must be signed in.', ar: 'يجب تسجيل الدخول.');
      });
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final list = await _transactionService.loadTransactionList(uid);
      if (!mounted) return;
      setState(() {
        transactionList = list;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = AppI18n.ts(
          en: 'Could not load transactions. Check Firebase rules.',
          ar: 'تعذر تحميل المعاملات. تحقق من قواعد Firebase.',
        );
      });
    }
  }

  // Keeps only the type for the selected tab. 0 = All.
  List<TransactionModel> filteredList() {
    if (tabController.index == 0) return transactionList;
    final wanted = ['all', 'income', 'expense', 'saving'][tabController.index];
    final list = <TransactionModel>[];
    for (final tx in transactionList) {
      if (tx.type == wanted) list.add(tx);
    }
    return list;
  }

  // Groups rows by year-month, newest month first.
  List<_MonthGroup> groupByMonth(List<TransactionModel> rows) {
    final groups = <String, _MonthGroup>{};
    final order = <String>[];
    for (final tx in rows) {
      final local = tx.date.toLocal();
      final key = '${local.year}-${local.month.toString().padLeft(2, '0')}';
      if (!groups.containsKey(key)) {
        order.add(key);
        groups[key] = _MonthGroup(
          heading: DateFormat('MMMM yyyy', AppSettingsController.instance.locale.toString()).format(local),
          rows: [],
        );
      }
      groups[key]!.rows.add(tx);
    }
    final result = <_MonthGroup>[];
    for (final key in order) {
      result.add(groups[key]!);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: ResponsiveContent(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                AppI18n.t(context, en: 'Transaction', ar: 'المعاملات'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F4D3D),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  _FilterTab(
                    label: AppI18n.t(context, en: 'All', ar: 'الكل'),
                    color: const Color(0xFF1F4D3D),
                    selected: tabController.index == 0,
                    onTap: () => tabController.animateTo(0),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: AppI18n.t(context, en: 'Income', ar: 'دخل'),
                    color: const Color(0xFF27AE60),
                    selected: tabController.index == 1,
                    onTap: () => tabController.animateTo(1),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: AppI18n.t(context, en: 'Expense', ar: 'مصروف'),
                    color: const Color(0xFFE74C3C),
                    selected: tabController.index == 2,
                    onTap: () => tabController.animateTo(2),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: AppI18n.t(context, en: 'Saving', ar: 'ادخار'),
                    color: const Color(0xFFD4A017),
                    selected: tabController.index == 3,
                    onTap: () => tabController.animateTo(3),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
        ),
      ),
    );
  }

  Widget _body() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF27AE60)),
      );
    }
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(errorMessage, textAlign: TextAlign.center),
        ),
      );
    }
    final rows = filteredList();
    if (rows.isEmpty) {
      return Center(
        child: Text(
          AppI18n.t(context, en: 'No transactions yet', ar: 'لا توجد معاملات بعد'),
          style: const TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    final months = groupByMonth(rows);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final month in months) ...[
          Text(
            month.heading,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F4D3D).withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < month.rows.length; i++) ...[
                  TransactionRow(transaction: month.rows[i]),
                  if (i < month.rows.length - 1)
                    const Divider(height: 1, color: Color(0xFFE8E8E8)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _MonthGroup {
  _MonthGroup({required this.heading, required this.rows});

  final String heading;
  final List<TransactionModel> rows;
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.16) : const Color(0xFFF3F1EB),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? color : const Color(0xFFE6E3DC),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: selected ? color : const Color(0xFF8A8F8A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
