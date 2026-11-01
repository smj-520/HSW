import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import './bills_screen.dart';
import './budget_screen.dart';
import '../models/home_finance_data.dart';
import '../navigation/app_transitions.dart';
import '../services/finance_repository.dart';
import '../services/user_profile_repository.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import './report_screen.dart';
import './transaction_screen.dart';
import '../widgets/home_widgets.dart';
import './add_transaction_screen.dart' hide AddBillScreen, ReportScreen;
import './add_bill_screen.dart';
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
    _financeSub = _financeRepo.watch(user.uid).listen(
      (data) {
        if (!mounted) return;
        setState(() => _data = data);
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _data = HomeFinanceData.empty());
      },
    );
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

  void _openAdd(TransactionKind kind) {
    Navigator.of(context).push(
      AppTransitions.fadeSlideSheet(
        AddTransactionScreen(kind: kind),
        routeName: '/add-${kind.name}',
      ),
    );
  }

  void _openBudget() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BudgetScreen()),
    );
  }

  void _openAddBill() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddBillScreen()),
    );
  }

  Future<void> _openAddPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
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
        onNotificationTap: () {
          Navigator.of(context).push(
            AppTransitions.fadeSlideSheet(
              NotificationsScreen(bills: _data.bills),
              routeName: '/notifications',
            ),
          );
        },
        onAddExpense: () => _openAdd(TransactionKind.expense),
        onAddIncome: () => _openAdd(TransactionKind.income),
        onAddSaving: () => _openAdd(TransactionKind.saving),
        onAddBill: _openAddBill,
        onOpenBudget: _openBudget,
        onViewAllOverview: () => setState(() => _index = 1),
        onViewAllBills: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BillsScreen()),
          );
        },
      ),
      const TransactionScreen(),
      const SizedBox.shrink(),
      const ReportScreen(),
      const SettingsScreen(isAdmin: false),
    ];

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _index,
        onSelected: _onNavSelected,
      ),
    );
  }
}
