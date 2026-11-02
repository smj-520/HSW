import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import './user_profile_repository.dart';
import '../constants/biller_categories.dart';
import '../models/admin_models.dart';

// This class only answers: who is logged in, and are they an admin?
class AdminAuthService {
  AdminAuthService({UserProfileRepository? profileRepo})
      : _profileRepo = profileRepo ?? UserProfileRepository();

  final UserProfileRepository _profileRepo;

  // Reads the role from Firebase for this user id. If missing, we treat them as a normal user.
  Future<String> getRole(String uid) async {
    final role = await _profileRepo.getUserRole(uid);
    if (role == null || role.isEmpty) {
      return 'user';
    }
    return role.toLowerCase();
  }

  // Returns true only when the role text is "admin".
  bool isAdmin(String role) {
    return role.toLowerCase() == 'admin';
  }

  // Signs this person out of Firebase Auth.
  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

// All user-list and block/unblock database work lives here, not in the screen.
class AdminUserService {
  AdminUserService({FirebaseDatabase? database})
      : _users = (database ?? FirebaseDatabase.instance).ref('users');

  final DatabaseReference _users;

  // Loads every user from Firebase. Returns an empty list if there are none.
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
      userList.add(
        UserModel(
          uid: uid,
          name: (name == null || name.isEmpty) ? 'No name' : name,
          email: email,
          role: (row['role'] as String?)?.toLowerCase() ?? 'user',
          isBlocked: row['blocked'] == true,
        ),
      );
    });
    userList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return userList;
  }

  // Sets blocked to true or false for this user id.
  Future<void> setBlocked({required String uid, required bool blocked}) {
    return _users.child(uid).update({'blocked': blocked});
  }
}

// Saves billers in Firebase under "billers". Users can read this list too.
class BillerService {
  BillerService({FirebaseDatabase? database})
      : _billers = (database ?? FirebaseDatabase.instance).ref('billers');

  final DatabaseReference _billers;

  // Loads every biller. Empty list if none exist yet.
  Future<List<BillerModel>> loadBillerList() async {
    final snapshot = await _billers.get();
    final value = snapshot.value;
    if (value is! Map) return [];

    final billerList = <BillerModel>[];
    value.forEach((key, dynamic raw) {
      if (raw is! Map) return;
      final row = raw.map((k, dynamic v) => MapEntry(k.toString(), v));
      final name = (row['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) return;
      billerList.add(
        BillerModel(
          id: key.toString(),
          name: name,
          category: (row['category'] as String?)?.trim() ?? '',
          accountNumber: (row['accountNumber'] as String?)?.trim() ?? '',
        ),
      );
    });
    billerList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return billerList;
  }

  // Adds a new biller. Returns if name, category, or account is empty.
  Future<String?> addBiller({
    required String name,
    required String category,
    required String accountNumber,
  }) async {
    final error = validateBillerFields(
      name: name,
      category: category,
      accountNumber: accountNumber,
    );
    if (error != null) return error;
    await _billers.push().set({
      'name': name.trim(),
      'category': resolveBillerCategoryId(category)!,
      'accountNumber': accountNumber.trim(),
    });
    return null;
  }

  // Updates an old biller. The form should already have the old values.
  Future<String?> updateBiller({
    required String id,
    required String name,
    required String category,
    required String accountNumber,
  }) async {
    final error = validateBillerFields(
      name: name,
      category: category,
      accountNumber: accountNumber,
    );
    if (error != null) return error;
    await _billers.child(id).update({
      'name': name.trim(),
      'category': resolveBillerCategoryId(category)!,
      'accountNumber': accountNumber.trim(),
    });
    return null;
  }

  // Deletes this biller from Firebase.
  Future<void> deleteBiller(String id) {
    return _billers.child(id).remove();
  }

}

// Feedback lives in Firebase under "feedback". Users add it. Admins only read it.
class FeedbackService {
  FeedbackService({FirebaseDatabase? database})
      : _feedback = (database ?? FirebaseDatabase.instance).ref('feedback');

  final DatabaseReference _feedback;

  // Saves one new message. Admin screens never call update or delete.
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

  // Loads all feedback, newest first.
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

// Payments live in Firebase under "payments". Users write them. Admins read them.
class ReportService {
  ReportService({FirebaseDatabase? database})
      : _payments = (database ?? FirebaseDatabase.instance).ref('payments');

  final DatabaseReference _payments;

  // Saves one payment when a user pays a biller.
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

  // Loads every payment. Returns an empty list if there are none.
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
}
