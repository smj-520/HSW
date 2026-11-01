// One bill the user saved. Amounts are in baisa (1000 baisa = 1 OMR).
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
  });

  final String id;
  final String userId;
  final String name;
  final int amountBaisa;
  final DateTime dueDate;
  // "unpaid" or "paid". Nothing else.
  final String status;
  final DateTime? paidDate;
  final String note;

  bool get isPaid => status == 'paid';
  bool get isUnpaid => !isPaid;
}
