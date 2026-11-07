import 'package:firebase_database/firebase_database.dart';

import '../models/transaction_model.dart';

class TransactionService {
  TransactionService({FirebaseDatabase? database})
      : _root = (database ?? FirebaseDatabase.instance).ref('finance');

  final DatabaseReference _root;

  Future<List<TransactionModel>> loadTransactionList(String uid) async {
    final snapshot = await _root.child(uid).child('transactions').get();
    final value = snapshot.value;
    if (value is! Map) return [];

    final transactionList = <TransactionModel>[];
    value.forEach((key, dynamic raw) {
      if (raw is! Map) return;
      final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
      final type = (row['kind'] as String?)?.trim().toLowerCase() ?? '';
      if (type != 'income' && type != 'expense' && type != 'saving') return;
      final amountBaisa = _asInt(row['amountBaisa']);
      if (amountBaisa <= 0) return;
      final note = row['note']?.toString().trim() ?? '';
      final titleText = row['title']?.toString().trim() ?? '';
      final title = titleText.isNotEmpty
          ? titleText
          : (note.isNotEmpty ? note : _fallbackTitle(type));
      final date = DateTime.tryParse(row['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final category = row['category']?.toString().trim();
      transactionList.add(
        TransactionModel(
          id: key.toString(),
          userId: uid,
          type: type,
          title: title,
          amountBaisa: amountBaisa,
          date: date,
          category: (category == null || category.isEmpty) ? null : category,
        ),
      );
    });
    transactionList.sort((a, b) => b.date.compareTo(a.date));
    return transactionList;
  }

  Future<void> addTransaction({
    required String uid,
    required String type,
    required int amountBaisa,
    required String title,
    DateTime? date,
    String? category,
  }) {
    if (amountBaisa <= 0) {
      return Future.error(ArgumentError('Enter an amount greater than 0'));
    }
    final kind = type.trim().toLowerCase();
    if (kind != 'income' && kind != 'expense' && kind != 'saving') {
      return Future.error(ArgumentError('Invalid transaction type'));
    }
    final when = (date ?? DateTime.now()).toUtc();
    final row = <String, Object>{
      'kind': kind,
      'amountBaisa': amountBaisa,
      'title': title.trim(),
      'note': title.trim(),
      'createdAt': when.toIso8601String(),
    };
    final cat = category?.trim();
    if (kind == 'expense' && cat != null && cat.isNotEmpty) {
      row['category'] = cat;
    }
    return _root.child(uid).child('transactions').push().set(row);
  }

  String _fallbackTitle(String type) {
    if (type == 'income') return 'Income';
    if (type == 'saving') return 'Saving';
    return 'Expense';
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
