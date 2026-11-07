import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import './user_profile_repository.dart';
import '../constants/biller_categories.dart';
import '../models/admin_models.dart';
import '../models/bill_model.dart';
import '../utils/admin_logic.dart';

class AdminAuthService {
  AdminAuthService({UserProfileRepository? profileRepo})
      : _profileRepo = profileRepo ?? UserProfileRepository();

  final UserProfileRepository _profileRepo;

  Future<String> getRole(String uid) async {
    final role = await _profileRepo.getUserRole(uid);
    if (role == null || role.isEmpty) {
      return 'user';
    }
    return role.toLowerCase();
  }

  bool isAdmin(String role) {
    return role.toLowerCase() == 'admin';
  }

  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

class AdminUserService {
  AdminUserService({FirebaseDatabase? database})
      : _users = (database ?? FirebaseDatabase.instance).ref('users');

  final DatabaseReference _users;

  Future<List<UserModel>> loadUserList() async {
    final snapshot = await _users.get();
    final value = snapshot.value;
    if (value is! Map) return [];

    final userList = <UserModel>[];
    value.forEach((key, dynamic raw) {
      if (raw is! Map) return;
      final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
      final uid = key.toString();
      final name = (row['displayName'] as String?)?.trim();
      final email = (row['email'] as String?)?.trim() ?? '';
      final phone = (row['phoneE164'] as String?)?.trim() ??
          (row['phone'] as String?)?.trim() ??
          '';
      userList.add(
        UserModel(
          uid: uid,
          name: (name == null || name.isEmpty) ? 'No name' : name,
          email: email,
          phone: phone,
          role: (row['role'] as String?)?.toLowerCase() ?? 'user',
          isBlocked: row['blocked'] == true ||
              (row['status'] as String?)?.toLowerCase() == 'blocked',
        ),
      );
    });
    userList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return userList;
  }

  Future<void> setBlocked({required String uid, required bool blocked}) {
    return _users.child(uid).update({
      'blocked': blocked,
      'status': blocked ? 'blocked' : 'active',
    });
  }
}

class BillerService {
  BillerService({FirebaseDatabase? database})
      : _billers = (database ?? FirebaseDatabase.instance).ref('billers');

  final DatabaseReference _billers;

  List<BillerModel> _parseList(Object? value) {
    if (value is! Map) return [];
    final billerList = <BillerModel>[];
    value.forEach((key, dynamic raw) {
      final parsed = _parseOne(key.toString(), raw);
      if (parsed != null) billerList.add(parsed);
    });
    billerList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return billerList;
  }

  BillerModel? _parseOne(String id, Object? raw) {
    if (raw is! Map) return null;
    final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
    final name = _asString(row['name']);
    if (name.isEmpty) return null;
    final activeRaw = row['active'];
    return BillerModel(
      id: id,
      name: name,
      category: _asString(row['category']),
      amountBaisa: _asInt(row['amountBaisa'] ?? row['amount']),
      userId: _asString(row['user_id'] ?? row['userId']),
      addedBy: _asString(row['addedBy'] ?? row['added_by']),
      source: _asString(row['source']),
      active: activeRaw != false,
    );
  }

  String _asString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? double.tryParse(raw)?.round() ?? 0;
  }

  Future<List<BillerModel>> loadBillerList() async {
    final snapshot = await _billers.get();
    return _parseList(snapshot.value);
  }

  Stream<List<BillerModel>> watchBillerList() {
    return _billers.onValue.map((event) => _parseList(event.snapshot.value));
  }

  Future<BillerModel?> fetchBiller(String id) async {
    final snapshot = await _billers.child(id).get();
    return _parseOne(id, snapshot.value);
  }

  List<BillerModel> visibleToStudent(
    List<BillerModel> all,
    String uid, {
    Set<String> adminUids = const {},
  }) {
    return [
      for (final biller in all)
        if (biller.isAdminBiller ||
            biller.ownerUserId == uid ||
            adminUids.contains(biller.ownerUserId))
          biller,
    ];
  }

  Future<String?> addBiller({
    required String name,
    required String category,
    bool active = true,
    String userId = '',
    String addedBy = '',
  }) async {
    final error = validateBillerFields(name: name, category: category);
    if (error != null) return error;
    final createError = validateNewBillerFields(name: name, category: category);
    if (createError != null) return createError;
    final existing = await loadBillerList();
    if (isDuplicateBillerNameAndCategory(
      name: name,
      category: resolveBillerCategoryId(category),
      existing: existing,
    )) {
      return AdminMessages.billerAlreadyExists;
    }
    final trimmed = name.trim();
    await _billers.push().set({
      'name': trimmed,
      'nameLower': normalizeBillerName(trimmed),
      'category': resolveBillerCategoryId(category)!,
      'active': active,
      'user_id': userId.trim(),
      'addedBy': userId.trim().isEmpty ? 'Admin' : addedBy.trim(),
      'source': userId.trim().isEmpty ? 'admin' : 'user',
    });
    return null;
  }

  Future<String?> updateBiller({
    required String id,
    required String name,
    required String category,
    bool active = true,
  }) async {
    final nameError = validateEditBillerName(name);
    if (nameError != null) return nameError;
    final error = validateBillerFields(name: name, category: category);
    if (error != null) return error;
    final existing = await loadBillerList();
    if (isDuplicateBillerNameAndCategory(
      name: name,
      category: resolveBillerCategoryId(category),
      existing: existing,
      ignoreId: id,
    )) {
      return AdminMessages.billerAlreadyExists;
    }
    final trimmed = name.trim();
    await _billers.child(id).update({
      'name': trimmed,
      'nameLower': normalizeBillerName(trimmed),
      'category': resolveBillerCategoryId(category)!,
      'active': active,
      'source': 'admin',
      'addedBy': 'Admin',
      'user_id': '',
    });
    return null;
  }

  Future<void> deleteBiller(String id) {
    return _billers.child(id).remove();
  }

}

class FeedbackService {
  FeedbackService({FirebaseDatabase? database})
      : _feedback = (database ?? FirebaseDatabase.instance).ref('feedback');

  final DatabaseReference _feedback;

  Future<void> addFeedback({
    required String uid,
    required String userName,
    required String message,
    required int rating,
  }) {
    return _feedback.push().set({
      'uid': uid,
      'userName': userName,
      'message': message.trim(),
      'rating': rating,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<FeedbackModel>> loadFeedbackList() async {
    final snapshot = await _feedback.get();
    final value = snapshot.value;
    if (value is! Map) return [];

    final list = <FeedbackModel>[];
    value.forEach((key, dynamic raw) {
      if (raw is! Map) return;
      final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
      final message = (row['message'] as String?)?.trim() ?? '';
      if (message.isEmpty) return;
      final ratingRaw = row['rating'];
      final rating = ratingRaw is int
          ? ratingRaw
          : int.tryParse(ratingRaw?.toString() ?? '') ?? 0;
      list.add(
        FeedbackModel(
          id: key.toString(),
          uid: row['uid']?.toString() ?? '',
          userName: (row['userName'] as String?)?.trim().isNotEmpty == true
              ? row['userName'].toString()
              : 'User',
          message: message,
          rating: rating.clamp(1, 5),
          createdAt: DateTime.tryParse(row['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    });
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}

class ReportService {
  ReportService({FirebaseDatabase? database})
      : _payments = (database ?? FirebaseDatabase.instance).ref('payments'),
        _finance = (database ?? FirebaseDatabase.instance).ref('finance'),
        _billReports = (database ?? FirebaseDatabase.instance).ref('billReports');

  final DatabaseReference _payments;
  final DatabaseReference _finance;
  final DatabaseReference _billReports;

  Future<void> addPayment({
    required String uid,
    required String billerId,
    required String billerName,
    required int amountBaisa,
  }) {
    return _payments.push().set({
      'uid': uid,
      'billerId': billerId,
      'billerName': billerName,
      'amountBaisa': amountBaisa,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<PaymentModel>> loadPaymentList() async {
    final snapshot = await _payments.get();
    final value = snapshot.value;
    if (value is! Map) return [];

    final paymentList = <PaymentModel>[];
    value.forEach((key, dynamic raw) {
      if (raw is! Map) return;
      final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
      final amount = row['amountBaisa'];
      final amountBaisa = amount is int
          ? amount
          : int.tryParse(amount?.toString() ?? '') ?? 0;
      if (amountBaisa <= 0) return;
      paymentList.add(
        PaymentModel(
          id: key.toString(),
          uid: row['uid']?.toString() ?? '',
          billerId: row['billerId']?.toString() ?? '',
          billerName: row['billerName']?.toString() ?? '',
          amountBaisa: amountBaisa,
          createdAt: DateTime.tryParse(row['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    });
    paymentList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return paymentList;
  }

  int _asAmount(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _asDate(Object? value) {
    if (value == null) return null;
    if (value is int) {
      if (value > 9999999999) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is num) {
      return _asDate(value.round());
    }
    return DateTime.tryParse(value.toString());
  }

  void _collectUserBills(String uid, Object? userRaw, List<BillModel> bills) {
    if (userRaw is! Map) return;
    final user = userRaw.map((k, dynamic v) => MapEntry(k.toString(), v));
    final billsRaw = user['bills'];
    if (billsRaw is Map) {
      billsRaw.forEach((billKey, dynamic raw) {
        if (raw is! Map) return;
        final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
        final name = (row['name'] as String?)?.trim() ?? '';
        final dueDate = _asDate(row['dueDate']) ?? _asDate(row['createdAt']);
        if (name.isEmpty || dueDate == null) return;
        final billerId = (row['billerId'] as String?)?.trim() ?? '';
        _addBillIfNew(
          bills,
          BillModel(
            id: billKey.toString(),
            userId: uid,
            name: name,
            amountBaisa: _asAmount(row['amountBaisa']),
            dueDate: dueDate,
            status: (row['status'] as String?)?.trim().toLowerCase() == 'paid'
                ? 'paid'
                : 'unpaid',
            paidDate: _asDate(row['paidDate']),
            billerId: billerId.isEmpty ? null : billerId,
            category: row['category']?.toString(),
            createdAt: _asDate(row['createdAt']),
          ),
        );
      });
    }
    final txsRaw = user['transactions'];
    if (txsRaw is Map) {
      txsRaw.forEach((txKey, dynamic raw) {
        if (raw is! Map) return;
        final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
        if ((row['kind']?.toString() ?? '') != 'expense') return;
        final amountBaisa = _asAmount(row['amountBaisa'] ?? row['amount']);
        if (amountBaisa <= 0) return;
        final when = _asDate(row['createdAt']) ?? _asDate(row['date']);
        if (when == null) return;
        final billerId = (row['billerId'] ?? row['biller_id'])?.toString().trim() ?? '';
        if (billerId.isEmpty) return;
        final name = (row['note'] as String?)?.trim().isNotEmpty == true
            ? row['note'].toString().trim()
            : 'Bill';
        _addBillIfNew(
          bills,
          BillModel(
            id: 'tx-$txKey',
            userId: uid,
            name: name,
            amountBaisa: amountBaisa,
            dueDate: when,
            status: 'paid',
            paidDate: when,
            billerId: billerId.isEmpty ? null : billerId,
            category: row['category']?.toString(),
            createdAt: when,
          ),
        );
      });
    }
  }

  void _addBillIfNew(List<BillModel> bills, BillModel bill) {
    for (final existing in bills) {
      if (existing.id == bill.id && existing.userId == bill.userId) return;
    }
    bills.add(bill);
  }

  Future<List<BillModel>> loadAllBillerBills() async {
    final bills = <BillModel>[];
    try {
      final reports = await _billReports.get();
      final value = reports.value;
      if (value is Map) {
        value.forEach((key, dynamic raw) {
          if (raw is! Map) return;
          final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
          final name = (row['name'] as String?)?.trim() ?? '';
          final due = _asDate(row['dueDate']) ?? _asDate(row['createdAt']);
          if (name.isEmpty || due == null) return;
          final uid = (row['userId'] ?? row['uid'])?.toString() ?? '';
          final billerId = (row['billerId'] as String?)?.trim() ?? '';
          _addBillIfNew(
            bills,
            BillModel(
              id: key.toString(),
              userId: uid,
              name: name,
              amountBaisa: _asAmount(row['amountBaisa']),
              dueDate: due,
              status: (row['status'] as String?)?.trim().toLowerCase() == 'paid'
                  ? 'paid'
                  : 'unpaid',
              paidDate: _asDate(row['paidDate']),
              billerId: billerId.isEmpty ? null : billerId,
              category: row['category']?.toString(),
              createdAt: _asDate(row['createdAt']),
            ),
          );
        });
      }
    } catch (_) {}
    try {
      final snapshot = await _finance.get();
      final value = snapshot.value;
      if (value is Map) {
        value.forEach((uidKey, dynamic userRaw) {
          _collectUserBills(uidKey.toString(), userRaw, bills);
        });
      }
    } catch (_) {}
    if (bills.isEmpty) {
      try {
        final usersSnap =
            await FirebaseDatabase.instance.ref('users').get();
        final users = usersSnap.value;
        if (users is Map) {
          for (final uidKey in users.keys) {
            final uid = uidKey.toString();
            try {
              final snap = await _finance.child(uid).get();
              _collectUserBills(uid, snap.value, bills);
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
    bills.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return bills;
  }
}
