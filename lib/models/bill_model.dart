class BillModel {
  const BillModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amountBaisa,
    required this.dueDate,
    required this.status,
    this.paidDate,
    this.note = '',
    this.billerId,
    this.category,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final int amountBaisa;
  final DateTime dueDate;
  final String status;
  final DateTime? paidDate;
  final String note;
  final String? billerId;
  final String? category;
  final DateTime? createdAt;

  bool get isPaid => status == 'paid';
  bool get isUnpaid => !isPaid;
}
