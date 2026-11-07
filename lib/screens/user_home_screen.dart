import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../core/finance_calculator.dart';
import '../models/bill_model.dart';
import '../models/home_finance_data.dart';
import '../services/budget_service.dart';
import '../navigation/app_transitions.dart';
import '../services/app_i18n.dart';
import '../services/bill_reminder_service.dart';
import '../services/bill_service.dart';
import '../core/transaction_clean_start.dart';
import '../services/finance_repository.dart';
import '../services/user_profile_repository.dart';
import '../utils/finance_math.dart';
import '../utils/formatters.dart';
import '../utils/wallet_tc_logic.dart';
import '../widgets/bills_widgets.dart';
import './report_screen.dart';
import './transaction_screen.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/blocked_account_guard.dart';
import './add_transaction_screen.dart' hide AddBillScreen, ReportScreen;
import './add_bill_screen.dart';
import './bills_screen.dart';
import './home_screen.dart';
import './settings_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _index = 0;
  String _firstName = 'there';
  HomeFinanceData _data = HomeFinanceData.empty();
  final _financeRepo = FinanceRepository();
  StreamSubscription<HomeFinanceData>? _financeSub;

  @override
  void initState() {
    super.initState();
    _loadFirstName();
    _listenFinance();
  }

  @override
  void dispose() {
    _financeSub?.cancel();
    super.dispose();
  }

  User? get _sessionUser {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser;
  }

  void _listenFinance() {
    _financeSub?.cancel();
    final user = _sessionUser;
    if (user == null) {
      setState(() => _data = HomeFinanceData.empty());
      return;
    }
    () async {
      try {
        await TransactionCleanStart.run(uid: user.uid);
      } catch (_) {}
      if (!mounted) return;
      _financeSub = _financeRepo.watch(user.uid).listen(
        (data) {
          if (!mounted) return;
          setState(() => _data = data);
          BillReminderService.instance.rescheduleUnpaid(user.uid);
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _data = HomeFinanceData.empty());
        },
      );
    }();
  }

  Future<void> _loadFirstName() async {
    final user = _sessionUser;
    Map<String, dynamic>? profile;
    if (user != null) {
      try {
        profile = await UserProfileRepository().getUserProfile(user.uid);
      } catch (_) {
        profile = null;
      }
    }
    if (!mounted) return;
    final profileName = (profile?['displayName'] as String?)?.trim();
    setState(() {
      _firstName = resolveFirstName(
        displayName: (profileName != null && profileName.isNotEmpty)
            ? profileName
            : user?.displayName,
        email: user?.email,
      );
    });
  }

  Future<void> _openBillDetails(BillItem bill) async {
    final model = BillModel(
      id: bill.id,
      userId: bill.userId.isNotEmpty ? bill.userId : (_sessionUser?.uid ?? ''),
      name: bill.name,
      amountBaisa: bill.amountBaisa,
      dueDate: bill.dueDate,
      status: bill.status,
      note: bill.note,
      billerId: bill.billerId,
      category: bill.category,
    );
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: UnpaidBillCard(
            bill: model,
            onMarkPaid: () async {
              Navigator.of(ctx).pop();
              final uid = _sessionUser?.uid;
              if (uid == null) return;
              final wallet = await _financeRepo.load(uid);
              final payError = payBillError(
                balanceBaisa: wallet.totalBalance,
                bill: model,
              );
              if (payError != null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(payError)),
                );
                return;
              }
              final error = await BillService().markBillAsPaid(uid: uid, bill: model);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    error ??
                        AppI18n.t(
                          context,
                          en: 'Bill marked as paid',
                          ar: 'تم تعليم الفاتورة كمدفوعة',
                        ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openAdd(TransactionKind kind) {
    Navigator.of(context).push(
      AppTransitions.fadeSlideSheet(
        AddTransactionScreen(kind: kind),
        routeName: '/add-${kind.name}',
      ),
    );
  }

  Future<void> _openAddPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddTransactionPickerSheet(
          onSelected: (kind) {
            Navigator.of(context).pop();
            _openAdd(kind);
          },
        );
      },
    );
  }

  void _onNavSelected(int index) {
    if (index == 2) {
      _openAddPicker();
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        firstName: _firstName,
        data: _data,
        onNotificationTap: () async {
          final overCats = <ExpenseCategory>[];
          final uid = _sessionUser?.uid;
          if (uid != null) {
            try {
              final list = await BudgetService().loadBudgetList(uid);
              final calc = FinanceCalculator.fromFinance(_data.transactions);
              final month = DateTime.now();
              final budgets = BudgetService().categoryBudgetMap(
                list.where((b) => sameMonth(b.date ?? DateTime.now(), month)).toList(),
              );
              for (final cat in kExpenseCategories) {
                final budget = budgets[cat.id] ?? 0;
                if (budget <= 0) continue;
                if (calc.categoryExpense(cat.id, month) > budget) {
                  overCats.add(cat);
                }
              }
            } catch (_) {}
          }
          if (!mounted) return;
          final warnings = [
            for (final cat in overCats)
              AppI18n.t(
                context,
                en: '${cat.label(context)} exceeded the monthly budget',
                ar: 'تجاوز ${cat.label(context)} الميزانية الشهرية',
              ),
          ];
          Navigator.of(context).push(
            AppTransitions.fadeSlideSheet(
              NotificationsScreen(
                bills: _data.bills,
                budgetWarnings: warnings,
              ),
              routeName: '/notifications',
            ),
          );
        },
        onAddExpenseSaved: ({
          required String categoryId,
          required String categoryName,
          required int amountBaisa,
          required String note,
          required DateTime date,
        }) async {
          final uid = _sessionUser?.uid;
          if (uid == null) return '';
          return _financeRepo.addTransaction(
            uid: uid,
            kind: TransactionKind.expense,
            amountBaisa: amountBaisa,
            note: note,
            category: categoryId,
            date: date,
          );
        },
        onUndoExpense: (id) async {
          final uid = _sessionUser?.uid;
          if (uid == null) return;
          await _financeRepo.deleteTransaction(uid: uid, id: id);
        },
        onViewAllOverview: () => setState(() => _index = 1),
        onViewAllBills: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BillsScreen()),
          );
        },
        onAddBill: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddBillScreen()),
          );
        },
        onBillTap: (bill) => _openBillDetails(bill),
      ),
      const TransactionScreen(),
      const SizedBox.shrink(),
      const ReportScreen(),
      const SettingsScreen(isAdmin: false),
    ];

    return BlockedAccountGuard(
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: AppBottomNav.student(
        context: context,
        currentIndex: _index,
        onSelected: _onNavSelected,
      ),
    ),
    );
  }
}
