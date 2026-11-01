import 'package:firebase_database/firebase_database.dart';

import '../models/home_finance_data.dart';
import './transaction_service.dart';
import '../models/bill_model.dart';

// All bill database work lives here. Screens must not talk to Firebase themselves.
class BillService {
  BillService({
    FirebaseDatabase? database,
    TransactionService? transactionService,
  })  : _billsRoot = (database ?? FirebaseDatabase.instance).ref('finance'),
        _transactionService = transactionService ?? TransactionService();

  final DatabaseReference _billsRoot;
  final TransactionService _transactionService;

  // Loads this user's bills. Empty list if they have not added any.
  Future<List<BillModel>> loadBillList(String uid) async {
    final snapshot = await _billsRoot.child(uid).child('bills').get();
    final value = snapshot.value;
    if (value is! Map) return [];

    final billList = <BillModel>[];
    value.forEach((key, dynamic raw) {
      if (raw is! Map) return;
      final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
      final name = (row['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) return;
      final dueDate = DateTime.tryParse(row['dueDate']?.toString() ?? '');
      if (dueDate == null) return;
      final status = (row['status'] as String?)?.trim().toLowerCase() ?? 'unpaid';
      billList.add(
        BillModel(
          id: key.toString(),
          userId: uid,
          name: name,
          amountBaisa: _asInt(row['amountBaisa']),
          dueDate: dueDate,
          status: status == 'paid' ? 'paid' : 'unpaid',
          paidDate: DateTime.tryParse(row['paidDate']?.toString() ?? ''),
          note: row['note']?.toString() ?? '',
        ),
      );
    });
    return billList;
  }

  // Bills that are not paid yet, newest due date last (soonest first).
  List<BillModel> unpaidBills(List<BillModel> billList) {
    final list = <BillModel>[];
    for (final bill in billList) {
      if (bill.isUnpaid) list.add(bill);
    }
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  // Paid bills = payment history. Newest paid date first.
  List<BillModel> paidBills(List<BillModel> billList) {
    final list = <BillModel>[];
    for (final bill in billList) {
      if (bill.isPaid) list.add(bill);
    }
    list.sort((a, b) {
      final aDate = a.paidDate ?? a.dueDate;
      final bDate = b.paidDate ?? b.dueDate;
      return bDate.compareTo(aDate);
    });
    return list;
  }

  // Keeps bills whose name contains the search text (not case sensitive).
  List<BillModel> filterBillsByName(List<BillModel> billList, String searchText) {
    final q = searchText.trim().toLowerCase();
    if (q.isEmpty) return billList;
    final list = <BillModel>[];
    for (final bill in billList) {
      if (bill.name.toLowerCase().contains(q)) list.add(bill);
    }
    return list;
  }

  // Saves a new unpaid bill for this user. Amount must already be in baisa.
  Future<void> addBill({
    required String uid,
    required String name,
    required int amountBaisa,
    required DateTime dueDate,
    String note = '',
  }) {
    final trimmed = name.trim();
    return _billsRoot.child(uid).child('bills').push().set({
      'userId': uid,
      'name': trimmed,
      'amountBaisa': amountBaisa,
      'dueDate': DateTime(dueDate.year, dueDate.month, dueDate.day)
          .toIso8601String(),
      'status': 'unpaid',
      'note': note.trim(),
      'kind': billKindFromName(trimmed).name,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Marks a bill paid once, saves the paid date, and adds an expense transaction.
  Future<String?> markBillAsPaid({
    required String uid,
    required BillModel bill,
  }) async {
    if (bill.isPaid) return 'This bill is already paid.';
    if (bill.amountBaisa <= 0) return 'This bill has no amount to pay.';
    final paidAt = DateTime.now();
    await _billsRoot.child(uid).child('bills').child(bill.id).update({
      'status': 'paid',
      'paidDate': paidAt.toUtc().toIso8601String(),
    });
    await _transactionService.addTransaction(
      uid: uid,
      type: 'expense',
      amountBaisa: bill.amountBaisa,
      title: bill.name,
      date: paidAt,
    );
    return null;
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
