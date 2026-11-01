import 'package:firebase_database/firebase_database.dart';

/// Realtime Database: `users/{uid}`.
///
/// **كلمات المرور لا تُخزَّن هنا ولا يمكن إظهارها في الداتابيس** — المصادقة في
/// Firebase Auth فقط (مهاشة على الخادم). هذا المسار للبيانات الظاهرة فقط
/// (الاسم، البريد، …) والطوابع الزمنية كنص ISO لسهولة المراجعة في الـ Console.
///
/// **Passwords are never written here.** Firebase Authentication stores credentials
/// securely (hashed server-side). This node stores **metadata** only, e.g.
/// `hasPassword`, `passwordUpdatedAt`, `lastLoginAt` — never password material.
/// Do not write default income, expenses, savings, bills, or balance here.
///
/// ```json
/// {
///   "rules": {
///     "users": {
///       ".read": "auth != null && root.child('users').child(auth.uid).child('role').val() === 'admin'",
///       "$uid": {
///         ".read": "auth != null && (auth.uid === $uid || root.child('users').child(auth.uid).child('role').val() === 'admin')",
///         ".write": "auth != null && (auth.uid === $uid || root.child('users').child(auth.uid).child('role').val() === 'admin')",
///         "role": {
///           ".validate": "(!data.exists() && newData.val() === 'user') || (data.exists() && newData.val() === data.val())"
///         }
///       }
///     },
///     "finance": {
///       "$uid": {
///         ".read": "$uid === auth.uid",
///         ".write": "$uid === auth.uid"
///       }
///     }
///   }
/// }
/// ```
class UserProfileRepository {
  UserProfileRepository({FirebaseDatabase? database})
      : _users = (database ?? FirebaseDatabase.instance).ref('users');

  final DatabaseReference _users;

  /// Readable in Firebase Console (UTC). Example: `2026-04-30T14:22:33.456789Z`.
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

  /// Call after a successful sign-in (any path).
  Future<void> touchLastLogin(String uid) {
    return _users.child(uid).update({
      'lastLoginAt': _isoUtcNow(),
    });
  }

  /// Call after the user changes password in-app (not for Firebase-only resets unless you wire it).
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

  // True only when the database field blocked is exactly true.
  Future<bool> isBlocked(String uid) async {
    final snapshot = await _users.child(uid).child('blocked').get();
    return snapshot.value == true;
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
