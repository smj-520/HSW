import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../models/bill_model.dart';
import '../widgets/bills_widgets.dart';
import '../services/bill_service.dart';
import './add_bill_screen.dart';

// Bills page: Unpaid and Paid lists from this user's Firebase data.
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _billService = BillService();
  final _search = TextEditingController();
  List<BillModel> billList = [];
  bool isLoading = true;
  String errorMessage = '';
  // true = Unpaid tab, false = Paid tab.
  bool showUnpaid = true;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    loadBills();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // The signed-in user's id, or null if nobody is logged in.
  String? sessionUid() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Downloads this user's bills.
  Future<void> loadBills() async {
    final uid = sessionUid();
    if (uid == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'You must be signed in.';
      });
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final list = await _billService.loadBillList(uid);
      if (!mounted) return;
      setState(() {
        billList = list;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not load bills. Check Firebase rules.';
      });
    }
  }

  // Opens Add Bill, then reloads the list when we come back.
  Future<void> openAddBill() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddBillScreen()),
    );
    await loadBills();
  }

  // Asks first, then marks the bill paid and adds an expense.
  Future<void> markBillAsPaid(BillModel bill) async {
    if (bill.isPaid) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppI18n.t(
              context,
              en: 'Are you sure you want to mark this bill as paid?',
              ar: 'هل أنت متأكد أنك تريد تعليم هذه الفاتورة كمدفوعة؟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppI18n.t(context, en: 'Cancel', ar: 'إلغاء')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppI18n.t(context, en: 'Yes', ar: 'نعم')),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final uid = sessionUid();
    if (uid == null) return;
    final error = await _billService.markBillAsPaid(uid: uid, bill: bill);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppI18n.t(context, en: 'Bill marked as paid', ar: 'تم تعليم الفاتورة كمدفوعة')),
      ),
    );
    setState(() => showUnpaid = false);
    await loadBills();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _billService.filterBillsByName(billList, searchText);
    final unpaidBills = _billService.unpaidBills(filtered);
    final paidBills = _billService.paidBills(filtered);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        title: Text(AppI18n.t(context, en: 'Bills', ar: 'الفواتير')),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF27AE60)),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(errorMessage, textAlign: TextAlign.center),
                    ),
                  )
                : ResponsiveContent(
                child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: _UnpaidPaidToggle(
                          showUnpaid: showUnpaid,
                          onChanged: (value) => setState(() => showUnpaid = value),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: SearchBox(
                          controller: _search,
                          onChanged: (text) => setState(() => searchText = text),
                        ),
                      ),
                      Expanded(
                        child: showUnpaid
                            ? _unpaidList(unpaidBills)
                            : _paidList(paidBills),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: openAddBill,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27AE60),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              AppI18n.t(context, en: 'Add Bill', ar: 'إضافة فاتورة'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  // Unpaid tab body.
  Widget _unpaidList(List<BillModel> unpaidBills) {
    if (billList.isEmpty) {
      return Center(
        child: Text(
          AppI18n.t(context, en: 'No bills yet', ar: 'لا توجد فواتير بعد'),
          style: const TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    if (unpaidBills.isEmpty) {
      return Center(
        child: Text(
          searchText.trim().isEmpty
              ? AppI18n.t(context, en: 'No unpaid bills', ar: 'لا توجد فواتير غير مدفوعة')
              : AppI18n.t(context, en: 'No bills match your search', ar: 'لا توجد فواتير مطابقة للبحث'),
          style: const TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          AppI18n.t(context, en: 'Unpaid Bills', ar: 'فواتير غير مدفوعة'),
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        for (final bill in unpaidBills)
          UnpaidBillCard(
            bill: bill,
            onMarkPaid: () => markBillAsPaid(bill),
          ),
      ],
    );
  }

  // Paid tab body (payment history).
  Widget _paidList(List<BillModel> paidBills) {
    if (paidBills.isEmpty) {
      return Center(
        child: Text(
          searchText.trim().isEmpty
              ? AppI18n.t(context, en: 'No paid bills yet', ar: 'لا توجد فواتير مدفوعة بعد')
              : AppI18n.t(context, en: 'No bills match your search', ar: 'لا توجد فواتير مطابقة للبحث'),
          style: const TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          AppI18n.t(context, en: 'Paid Bills', ar: 'فواتير مدفوعة'),
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        for (final bill in paidBills) PaidBillCard(bill: bill),
      ],
    );
  }
}

// Green / grey pills for Unpaid and Paid.
class _UnpaidPaidToggle extends StatelessWidget {
  const _UnpaidPaidToggle({
    required this.showUnpaid,
    required this.onChanged,
  });

  final bool showUnpaid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEDE8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: _pill(
              label: AppI18n.t(context, en: 'Unpaid', ar: 'غير مدفوعة'),
              selected: showUnpaid,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _pill(
              label: AppI18n.t(context, en: 'Paid', ar: 'مدفوعة'),
              selected: !showUnpaid,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF27AE60) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
