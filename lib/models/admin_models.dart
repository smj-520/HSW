class BillerModel {
  const BillerModel({
    required this.id,
    required this.name,
    required this.category,
    this.amountBaisa = 0,
    this.userId,
    this.addedBy,
    this.source,
    this.active = true,
  });

  final String id;
  final String name;
  final String category;
  final int amountBaisa;
  final String? userId;
  final String? addedBy;
  final String? source;
  final bool? active;

  String get ownerUserId => (userId ?? '').trim();
  String get addedByLabel => (addedBy ?? '').trim();
  bool get isActive => active != false;
  bool get isAdminBiller =>
      ownerUserId.isEmpty ||
      (source ?? '').toLowerCase() == 'admin' ||
      addedByLabel.toLowerCase() == 'admin';
}

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

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isBlocked,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isBlocked;

  String get status => isBlocked ? 'Blocked' : 'Active';

  bool get isAdmin => role.toLowerCase() == 'admin';
}
