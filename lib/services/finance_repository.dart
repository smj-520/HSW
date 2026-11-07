import 'package:firebase_database/firebase_database.dart';

import '../constants/categories.dart';
import '../core/finance_calculator.dart';
import '../core/transaction_validator.dart';
import '../models/home_finance_data.dart';

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
    DateTime? date,
    String? billerId,
  }) async {
    if (amountBaisa <= 0) {
      throw ArgumentError('Enter an amount greater than 0');
    }
    final current = await load(uid);
    final check = TransactionValidator(
      FinanceCalculator.fromFinance(current.transactions),
    ).validateAdd(
      kind: kind.name,
      amountBaisa: amountBaisa,
      category: category,
    );
    if (!check.ok) {
      throw ArgumentError(check.message);
    }
    final when = date ?? DateTime.now();
    final row = <String, Object>{
      'kind': kind.name,
      'amountBaisa': amountBaisa,
      'note': note.trim(),
      'createdAt': when.toUtc().toIso8601String(),
    };
    final cat = category?.trim();
    if (kind == TransactionKind.expense && cat != null && cat.isNotEmpty) {
      row['category'] = cat;
    }
    final biller = billerId?.trim() ?? '';
    if (biller.isNotEmpty) {
      row['billerId'] = biller;
      row['userId'] = uid;
    }
    final ref = _root.child(uid).child('transactions').push();
    await ref.set(row);
    return ref.key ?? '';
  }

  Future<void> deleteTransaction({
    required String uid,
    required String id,
  }) async {
    final current = await load(uid);
    CalcTx? old;
    for (final tx in current.transactions) {
      if (tx.id == id) {
        old = CalcTx.fromFinance(tx);
        break;
      }
    }
    if (old != null) {
      final check = TransactionValidator(
        FinanceCalculator.fromFinance(current.transactions),
      ).validateDelete(old);
      if (!check.ok) {
        throw ArgumentError(check.message);
      }
    }
    await _root.child(uid).child('transactions').child(id).remove();
  }

  Future<void> updateTransaction({
    required String uid,
    required String id,
    required TransactionKind kind,
    required int amountBaisa,
    String note = '',
    String? category,
  }) {
    if (amountBaisa <= 0) {
      return Future.error(ArgumentError('Enter an amount greater than 0'));
    }
    return load(uid).then((current) {
      CalcTx? old;
      for (final tx in current.transactions) {
        if (tx.id == id) {
          old = CalcTx.fromFinance(tx);
          break;
        }
      }
      final validator = TransactionValidator(
        FinanceCalculator.fromFinance(current.transactions),
      );
      final check = old == null
          ? validator.validateAdd(kind: kind.name, amountBaisa: amountBaisa, category: category)
          : validator.validateEdit(
              old: old,
              kind: kind.name,
              amountBaisa: amountBaisa,
              category: category,
            );
      if (!check.ok) {
        return Future<void>.error(ArgumentError(check.message));
      }
      return _writeUpdate(
        uid: uid,
        id: id,
        kind: kind,
        amountBaisa: amountBaisa,
        note: note,
        category: category,
      );
    });
  }

  Future<void> _writeUpdate({
    required String uid,
    required String id,
    required TransactionKind kind,
    required int amountBaisa,
    String note = '',
    String? category,
  }) {
    final row = <String, Object?>{
      'kind': kind.name,
      'amountBaisa': amountBaisa,
      'note': note.trim(),
    };
    final cat = category?.trim();
    if (kind == TransactionKind.expense && cat != null && cat.isNotEmpty) {
      row['category'] = cat;
    } else {
      row['category'] = null;
    }
    return _root.child(uid).child('transactions').child(id).update(row);
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
      final amount = _asInt(row['amountBaisa'] ?? row['amount']);
      if (kind == null || amount <= 0) continue;
      final category = row['category']?.toString().trim();
      transactions.add(
        FinanceTransaction(
          id: entry.key,
          kind: kind,
          amountBaisa: amount,
          note: row['note']?.toString() ?? '',
          createdAt: DateTime.tryParse(row['createdAt']?.toString() ?? '') ??
              DateTime.tryParse(row['date']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
          category: kind == TransactionKind.expense
              ? normalizeExpenseCategoryId(category)
              : ((category == null || category.isEmpty) ? null : category),
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
      final status = row['status']?.toString().trim().toLowerCase() ?? 'unpaid';
      bills.add(
        BillItem(
          id: entry.key,
          name: name,
          dueDate: due,
          kind: billKindFromStorage(row['kind']?.toString()),
          amountBaisa: _asInt(row['amountBaisa']),
          status: status == 'paid' ? 'paid' : 'unpaid',
          category: normalizeExpenseCategoryId(
            row['category']?.toString() ?? row['kind']?.toString(),
          ),
          userId: row['userId']?.toString() ?? '',
          billerId: (row['billerId'] as String?)?.trim(),
          note: row['note']?.toString() ?? '',
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
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? double.tryParse(raw)?.round() ?? 0;
  }
}
