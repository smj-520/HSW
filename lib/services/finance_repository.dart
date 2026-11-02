import 'package:firebase_database/firebase_database.dart';

import '../models/home_finance_data.dart';

/// Realtime Database: `finance/{uid}/transactions` and `finance/{uid}/bills`.
///
/// No records are created at registration. A new user has no node (or empty
/// maps) until they add income, expense, saving, or a bill.
///
/// Example rules:
/// ```json
/// {
///   "rules": {
///     "finance": {
///       "$uid": {
///         ".read": "$uid === auth.uid",
///         ".write": "$uid === auth.uid"
///       }
///     }
///   }
/// }
/// ```
class FinanceRepository {
  FinanceRepository({FirebaseDatabase? database})
      : _root = (database ?? FirebaseDatabase.instance).ref('finance');

  final DatabaseReference _root;

  Stream<HomeFinanceData> watch(String uid) {
    return _root.child(uid).onValue.map((event) {
      return _parse(event.snapshot.value);
    });
  }

  Future<HomeFinanceData> load(String uid) async {
    final snapshot = await _root.child(uid).get();
    return _parse(snapshot.value);
  }

  Future<String> addTransaction({
    required String uid,
    required TransactionKind kind,
    required int amountBaisa,
    String note = '',
    String? category,
  }) async {
    final row = <String, Object>{
      'kind': kind.name,
      'amountBaisa': amountBaisa,
      'note': note.trim(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    // Only expenses keep a budget category. Old expenses with no category still work.
    final cat = category?.trim();
    if (kind == TransactionKind.expense && cat != null && cat.isNotEmpty) {
      row['category'] = cat;
    }
    final ref = _root.child(uid).child('transactions').push();
    await ref.set(row);
    return ref.key ?? '';
  }

  Future<void> deleteTransaction({
    required String uid,
    required String id,
  }) {
    return _root.child(uid).child('transactions').child(id).remove();
  }

  Future<void> addBill({
    required String uid,
    required String name,
    required DateTime dueDate,
    BillKind? kind,
  }) {
    final trimmed = name.trim();
    return _root.child(uid).child('bills').push().set({
      'name': trimmed,
      'dueDate': DateTime(dueDate.year, dueDate.month, dueDate.day)
          .toIso8601String(),
      'kind': (kind ?? billKindFromName(trimmed)).name,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  HomeFinanceData _parse(Object? value) {
    if (value is! Map) return HomeFinanceData.empty();
    final root = _asMap(value);

    final transactions = <FinanceTransaction>[];
    final txMap = _asMap(root['transactions']);
    for (final entry in txMap.entries) {
      final row = _asMap(entry.value);
      final kind = transactionKindFromStorage(row['kind']?.toString());
      final amount = _asInt(row['amountBaisa']);
      if (kind == null || amount <= 0) continue;
      final category = row['category']?.toString().trim();
      transactions.add(
        FinanceTransaction(
          id: entry.key,
          kind: kind,
          amountBaisa: amount,
          note: row['note']?.toString() ?? '',
          createdAt: DateTime.tryParse(row['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
          category: (category == null || category.isEmpty) ? null : category,
        ),
      );
    }

    final bills = <BillItem>[];
    final billMap = _asMap(root['bills']);
    for (final entry in billMap.entries) {
      final row = _asMap(entry.value);
      final name = row['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      final due = DateTime.tryParse(row['dueDate']?.toString() ?? '');
      if (due == null) continue;
      bills.add(
        BillItem(
          id: entry.key,
          name: name,
          dueDate: due,
          kind: billKindFromStorage(row['kind']?.toString()),
        ),
      );
    }

    return HomeFinanceData.fromRecords(
      transactions: transactions,
      bills: bills,
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    return {};
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
