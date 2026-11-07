import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/bill_model.dart';
import 'bill_service.dart';

class BillReminderService {
  BillReminderService._();
  static final BillReminderService instance = BillReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Muscat'));
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  int _id(String billId, {required bool dayBefore}) {
    final base = billId.hashCode & 0x3fffffff;
    return dayBefore ? base : base + 1;
  }

  Future<void> cancelForBill(String billId) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_id(billId, dayBefore: true));
      await _plugin.cancel(_id(billId, dayBefore: false));
    } catch (_) {}
  }

  Future<void> scheduleForBill(BillModel bill) async {
    if (!_ready || bill.isPaid) return;
    await cancelForBill(bill.id);
    final due = DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day, 9);
    final before = due.subtract(const Duration(days: 1));
    await _schedule(
      id: _id(bill.id, dayBefore: true),
      when: before,
      title: 'Bill due tomorrow',
      body: '${bill.name} is due tomorrow.',
    );
    await _schedule(
      id: _id(bill.id, dayBefore: false),
      when: due,
      title: 'Bill due today',
      body: '${bill.name} is due today.',
    );
  }

  Future<void> rescheduleUnpaid(String uid) async {
    try {
      final all = await BillService().loadBillList(uid);
      final bills = BillService().unpaidBills(all);
      for (final bill in bills) {
        await scheduleForBill(bill);
      }
    } catch (_) {}
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    final now = DateTime.now();
    if (!when.isAfter(now)) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bills',
            'Bill reminders',
            channelDescription: 'Due-date reminders for hostel bills',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }
}
