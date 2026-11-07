import 'package:firebase_database/firebase_database.dart';

import '../constants/biller_categories.dart';
import '../constants/categories.dart';
import '../models/home_finance_data.dart';
import './admin_services.dart';
import './bill_reminder_service.dart';
import './finance_repository.dart';
import '../core/finance_calculator.dart';
import '../core/transaction_validator.dart';
import '../models/bill_model.dart';

class BillService {
  BillService({FirebaseDatabase? database})
      : _billsRoot = (database ?? FirebaseDatabase.instance).ref('finance'),
        _reports = (database ?? FirebaseDatabase.instance).ref('billReports'),
        _payments = (database ?? FirebaseDatabase.instance).ref('payments');

  final DatabaseReference _billsRoot;
  final DatabaseReference _reports;
  final DatabaseReference _payments;

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
          billerId: (row['billerId'] as String?)?.trim(),
          category: normalizeExpenseCategoryId(
            row['category']?.toString() ?? row['kind']?.toString(),
          ),
        ),
      );
    });
    return billList;
  }

  List<BillModel> unpaidBills(List<BillModel> billList) {
    final list = <BillModel>[];
    for (final bill in billList) {
      if (bill.isUnpaid) list.add(bill);
    }
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

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

  List<BillModel> filterBillsByName(List<BillModel> billList, String searchText) {
    final q = searchText.trim().toLowerCase();
    if (q.isEmpty) return billList;
    final list = <BillModel>[];
    for (final bill in billList) {
      if (bill.name.toLowerCase().contains(q)) list.add(bill);
    }
    return list;
  }

  Future<void> addBill({
    required String uid,
    required String name,
    required int amountBaisa,
    required DateTime dueDate,
    String note = '',
    String? billerId,
    String? category,
  }) {
    if (amountBaisa <= 0) {
      return Future.error(ArgumentError('Enter an amount greater than 0'));
    }
    final trimmed = name.trim();
    final row = <String, Object>{
      'userId': uid,
      'name': trimmed,
      'amountBaisa': amountBaisa,
      'dueDate': DateTime(dueDate.year, dueDate.month, dueDate.day)
          .toIso8601String(),
      'status': 'unpaid',
      'note': note.trim(),
      'kind': billKindFromName(trimmed).name,
      'category': normalizeExpenseCategoryId(category ?? trimmed),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    final linked = billerId?.trim() ?? '';
    if (linked.isNotEmpty) row['billerId'] = linked;
    final billRef = _billsRoot.child(uid).child('bills').push();
    return billRef.set(row).then((_) async {
      final id = billRef.key ?? '';
      final copy = Map<String, Object>.from(row);
      if (id.isNotEmpty) copy['billId'] = id;
      await _writeAdminCopy(id, copy);
      return BillReminderService.instance.rescheduleUnpaid(uid);
    });
  }

  Future<void> _writeAdminCopy(String id, Map<String, Object> row) async {
    if (id.isEmpty) return;
    try {
      await _reports.child(id).set(row);
    } catch (_) {}
    try {
      await _payments.child(id).set({
        'uid': row['userId'] ?? '',
        'billerId': row['billerId'] ?? '',
        'billerName': row['name'] ?? '',
        'amountBaisa': row['amountBaisa'] ?? 0,
        'createdAt': row['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
        'dueDate': row['dueDate'] ?? '',
        'category': row['category'] ?? '',
        'status': row['status'] ?? 'unpaid',
      });
    } catch (_) {}
  }

  Future<String?> markBillAsPaid({
    required String uid,
    required BillModel bill,
  }) async {
    if (bill.isPaid) return 'This bill is already paid.';
    if (bill.amountBaisa <= 0) return 'This bill has no amount to pay.';
    final wallet = await FinanceRepository().load(uid);
    final payCheck = TransactionValidator(
      FinanceCalculator.fromFinance(wallet.transactions),
    ).validateBillPay(bill.amountBaisa);
    if (!payCheck.ok) return payCheck.message;
    final linkedId = bill.billerId?.trim() ?? '';
    if (linkedId.isNotEmpty) {
      final latest = await BillerService().fetchBiller(linkedId);
      final cap = latest?.amountBaisa ?? 0;
      if (exceedsBillerCap(amountBaisa: bill.amountBaisa, capBaisa: cap)) {
        return billerCapExceededMessage(
          displayBillerCapBaisa(amountBaisa: bill.amountBaisa, capBaisa: cap),
        );
      }
    }
    final paidAt = DateTime.now();
    final txRef = _billsRoot.child(uid).child('transactions').push();
    final paidIso = paidAt.toUtc().toIso8601String();
    await _billsRoot.child(uid).update({
      'bills/${bill.id}/status': 'paid',
      'bills/${bill.id}/paidDate': paidIso,
      'transactions/${txRef.key}': {
        'kind': 'expense',
        'amountBaisa': bill.amountBaisa,
        'note': bill.name,
        'title': bill.name,
        'type': 'expense',
        'category': normalizeExpenseCategoryId(bill.category ?? bill.name),
        'createdAt': paidAt.toUtc().toIso8601String(),
        'date': paidAt.toUtc().toIso8601String(),
        if (linkedId.isNotEmpty) 'billerId': linkedId,
        'userId': uid,
      },
    });
    await _writeAdminCopy(bill.id, {
      'userId': uid,
      'name': bill.name,
      'amountBaisa': bill.amountBaisa,
      'dueDate': DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day)
          .toIso8601String(),
      'status': 'paid',
      'paidDate': paidIso,
      'category': normalizeExpenseCategoryId(bill.category ?? bill.name),
      if (linkedId.isNotEmpty) 'billerId': linkedId,
      'createdAt': paidIso,
    });
    await BillReminderService.instance.cancelForBill(bill.id);
    await BillReminderService.instance.rescheduleUnpaid(uid);
    return null;
  }

  Future<void> deleteBill({required String uid, required String billId}) async {
    await _billsRoot.child(uid).child('bills').child(billId).remove();
    try {
      await _reports.child(billId).remove();
    } catch (_) {}
    try {
      await _payments.child(billId).remove();
    } catch (_) {}
    await BillReminderService.instance.cancelForBill(billId);
    await BillReminderService.instance.rescheduleUnpaid(uid);
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? double.tryParse(raw)?.round() ?? 0;
  }
}
