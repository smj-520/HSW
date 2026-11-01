// One company the admin adds so users can pay bills.
class BillerModel {
  const BillerModel({
    required this.id,
    required this.name,
    required this.category,
    required this.accountNumber,
  });

  final String id;
  final String name;
  final String category;
  final String accountNumber;
}

// One piece of feedback a user sent to the admin.
class FeedbackModel {
  const FeedbackModel({
    required this.id,
    required this.uid,
    required this.userName,
    required this.message,
    required this.rating,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String userName;
  final String message;
  final int rating;
  final DateTime createdAt;
}

// One payment a user made toward a biller (used in the admin report).
class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.uid,
    required this.billerId,
    required this.billerName,
    required this.amountBaisa,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String billerId;
  final String billerName;
  final int amountBaisa;
  final DateTime createdAt;
}

// One person from the users list in Firebase.
class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isBlocked,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final bool isBlocked;

  // Short status text for the list.
  String get status => isBlocked ? 'Blocked' : 'Active';

  // True when this account is an admin.
  bool get isAdmin => role.toLowerCase() == 'admin';
}
