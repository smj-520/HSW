class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.amountBaisa,
    required this.date,
    this.category,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final int amountBaisa;
  final DateTime date;
  final String? category;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isSaving => type == 'saving';
}
