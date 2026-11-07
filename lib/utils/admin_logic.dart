import '../models/admin_models.dart';
import '../models/bill_model.dart';

abstract final class AdminMessages {
  static const accountBlocked = 'account is blocked';
  static const allFieldsRequired = 'All fields are required.';
  static const billerAlreadyExists = 'Biller already exists.';
  static const nameRequired = 'Name is required.';
  static const userBlocked = 'User blocked.';
  static const userUnblocked = 'User unblocked.';
}

String normalizeBillerName(String name) => name.trim().toLowerCase();

bool isDuplicateBillerName({
  required String name,
  required Iterable<BillerModel> existing,
  String? ignoreId,
}) {
  final key = normalizeBillerName(name);
  if (key.isEmpty) return false;
  for (final biller in existing) {
    if (ignoreId != null && biller.id == ignoreId) continue;
    if (normalizeBillerName(biller.name) == key) return true;
  }
  return false;
}

bool isDuplicateBillerNameAndCategory({
  required String name,
  required String? category,
  required Iterable<BillerModel> existing,
  String? ignoreId,
}) {
  final key = normalizeBillerName(name);
  final cat = (category ?? '').trim().toLowerCase();
  if (key.isEmpty || cat.isEmpty) return false;
  for (final biller in existing) {
    if (ignoreId != null && biller.id == ignoreId) continue;
    if (normalizeBillerName(biller.name) == key &&
        biller.category.trim().toLowerCase() == cat) {
      return true;
    }
  }
  return false;
}

String? validateNewBillerFields({
  required String name,
  required String? category,
  int? amountBaisa,
}) {
  final missingName = name.trim().isEmpty;
  final missingCategory = category == null || category.trim().isEmpty;
  if (missingName || missingCategory) {
    return AdminMessages.allFieldsRequired;
  }
  return null;
}

String? validateEditBillerName(String name) {
  if (name.trim().isEmpty) return AdminMessages.nameRequired;
  return null;
}

List<UserModel> filterUsersByName(List<UserModel> users, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return users;
  return [
    for (final user in users)
      if (user.name.toLowerCase().contains(q)) user,
  ];
}

bool billInDateRange(DateTime dueDate, DateTime start, DateTime end) {
  final day = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final from = DateTime(start.year, start.month, start.day);
  final to = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
  return !day.isBefore(from) && !day.isAfter(to);
}

bool billMatchesReportRange(BillModel bill, DateTime start, DateTime end) {
  if (billInDateRange(bill.dueDate, start, end)) return true;
  if (bill.createdAt != null && billInDateRange(bill.createdAt!, start, end)) {
    return true;
  }
  if (bill.paidDate != null && billInDateRange(bill.paidDate!, start, end)) {
    return true;
  }
  return false;
}

List<BillModel> filterBillsForBillerReport({
  required List<BillModel> bills,
  required String billerIdOrAll,
  DateTime? start,
  DateTime? end,
}) {
  return [
    for (final bill in bills)
      if ((billerIdOrAll == 'all' || bill.billerId == billerIdOrAll) &&
          (start == null ||
              end == null ||
              billMatchesReportRange(bill, start, end)))
        bill,
  ];
}

Map<String, int> billerTotals(List<BillModel> bills) {
  final map = <String, int>{};
  for (final bill in bills) {
    final key = bill.billerId ?? bill.name;
    map[key] = (map[key] ?? 0) + bill.amountBaisa;
  }
  return map;
}
