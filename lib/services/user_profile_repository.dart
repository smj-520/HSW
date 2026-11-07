import 'package:firebase_database/firebase_database.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseDatabase? database})
      : _users = (database ?? FirebaseDatabase.instance).ref('users');

  final DatabaseReference _users;

  static String _isoUtcNow() => DateTime.now().toUtc().toIso8601String();

  Future<void> saveNewUserProfile({
    required String uid,
    required String displayName,
    required String email,
    required String phoneE164,
    required String countryIso,
    required String role,
  }) {
    return _users.child(uid).set({
      'displayName': displayName,
      'email': email,
      'phoneE164': phoneE164,
      'countryIso': countryIso,
      'role': role,
      'createdAt': _isoUtcNow(),
      'hasPassword': true,
      'passwordUpdatedAt': _isoUtcNow(),
    });
  }

  Future<void> touchLastLogin(String uid) {
    return _users.child(uid).update({
      'lastLoginAt': _isoUtcNow(),
    });
  }

  Future<void> touchPasswordUpdated(String uid) {
    return _users.child(uid).update({
      'hasPassword': true,
      'passwordUpdatedAt': _isoUtcNow(),
    });
  }

  Future<String?> getUserRole(String uid) async {
    final snapshot = await _users.child(uid).child('role').get();
    final value = snapshot.value;
    if (value is String && value.trim().isNotEmpty) {
      return value.trim().toLowerCase();
    }
    return null;
  }

  Future<bool> isBlocked(String uid) async {
    final snapshot = await _users.child(uid).get();
    final value = snapshot.value;
    if (value is Map) {
      final row = value.map((k, dynamic v) => MapEntry(k.toString(), v));
      if (row['blocked'] == true) return true;
      return (row['status'] as String?)?.toLowerCase() == 'blocked';
    }
    return snapshot.child('blocked').value == true;
  }

  Stream<bool> watchBlocked(String uid) {
    return _users.child(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        final row = value.map((k, dynamic v) => MapEntry(k.toString(), v));
        if (row['blocked'] == true) return true;
        return (row['status'] as String?)?.toLowerCase() == 'blocked';
      }
      return false;
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _users.child(uid).get();
    final value = snapshot.value;
    if (value is Map) {
      return value.map(
        (key, dynamic v) => MapEntry(key.toString(), v),
      );
    }
    return null;
  }

  Future<void> updateProfileBasics({
    required String uid,
    required String displayName,
    required String phoneE164,
    required String countryIso,
    String? photoUrl,
  }) {
    return _users.child(uid).update({
      'displayName': displayName,
      'phoneE164': phoneE164,
      'countryIso': countryIso,
      'photoUrl': photoUrl,
      'updatedAt': _isoUtcNow(),
    });
  }
}
