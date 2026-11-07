import 'dart:convert';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionCleanStart {
  static const flagKey = 'clean_start_done_v1';

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(flagKey) ?? false;
  }

  static Object? _jsonSafe(Object? value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _jsonSafe(v)));
    }
    if (value is Iterable && value is! String) {
      return [for (final item in value) _jsonSafe(item)];
    }
    return value;
  }

  static Future<String?> run({
    required String uid,
    FirebaseDatabase? database,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(flagKey) ?? false) return null;

    final root = (database ?? FirebaseDatabase.instance).ref('finance').child(uid);
    final txRef = root.child('transactions');
    final snapshot = await txRef.get();
    final raw = snapshot.value;

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/transactions_backup_$stamp.json');
    await file.writeAsString(
      jsonEncode({'uid': uid, 'transactions': _jsonSafe(raw)}),
    );

    await txRef.remove();
    await prefs.setBool(flagKey, true);
    return file.path;
  }
}
