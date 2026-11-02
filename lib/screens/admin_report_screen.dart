import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../utils/formatters.dart';
import '../models/admin_models.dart';
import '../services/admin_services.dart';
import '../widgets/admin_widgets.dart';


// Admin report: filter billers and dates, then show numbers, a pie chart, and a list....
class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  final _reportService = ReportService();
  final _billerService = BillerService();
  bool isLoading = true;
  String errorMessage = '';
  List<BillerModel> billerList = [];
  List<PaymentModel> paymentList = [];
  String selectedBillerId = 'all';
  DateTimeRange? dateRange;

  static const _chartColors = [
    Color(0xFF2E7D5B),
    Color(0xFFE74C3C),
    Color(0xFFD4A017),
    Color(0xFF4A90E2),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
  ];

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  // Downloads billers and payments from Firebase.
  Future<void> loadReport() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final billers = await _billerService.loadBillerList();
      final payments = await _reportService.loadPaymentList();
      if (!mounted) return;
      setState(() {
        billerList = billers;
        paymentList = payments;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not load the report. Check Firebase rules.';
      });
    }
  }

  // Opens the calendar so the admin can pick a start date and an end date.
  Future<void> pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: dateRange,
    );
    if (picked != null) {
      setState(() => dateRange = picked);
    }
  }

  // Clears the date filter so we show every payment again.
  void clearDates() {
    setState(() => dateRange = null);
  }

  // Payments that match the dropdown and the date range.
  List<PaymentModel> filteredPayments() {
    return paymentList.where((pay) {
      if (selectedBillerId != 'all' && pay.billerId != selectedBillerId) {
        return false;
      }
      if (dateRange != null) {
        final day = DateTime(pay.createdAt.year, pay.createdAt.month, pay.createdAt.day);
        final start = DateTime(
          dateRange!.start.year,
          dateRange!.start.month,
          dateRange!.start.day,
        );
        final end = DateTime(
          dateRange!.end.year,
          dateRange!.end.month,
          dateRange!.end.day,
        );
        if (day.isBefore(start) || day.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  // Adds up payment amounts for each biller name (for the pie chart).
  Map<String, int> totalsByBiller(List<PaymentModel> rows) {
    final map = <String, int>{};
    for (final pay in rows) {
      final key = pay.billerName.isEmpty ? 'Unknown' : pay.billerName;
      map[key] = (map[key] ?? 0) + pay.amountBaisa;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage.isNotEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(errorMessage, textAlign: TextAlign.center),
      ));
    }

    final rows = filteredPayments();
    final byBiller = totalsByBiller(rows);
    var totalAmount = 0;
    for (final pay in rows) {
      totalAmount += pay.amountBaisa;
    }
    final dateLabel = dateRange == null
        ? AppI18n.t(context, en: 'All dates', ar: 'كل التواريخ')
        : '${DateFormat('yyyy-MM-dd').format(dateRange!.start)} → ${DateFormat('yyyy-MM-dd').format(dateRange!.end)}';

    return ResponsiveContent(
      child: ListView(
      padding: EdgeInsets.all(responsivePagePaddingX(MediaQuery.sizeOf(context).width)),
      children: [
        DropdownButton<String>(
          isExpanded: true,
          value: selectedBillerId,
          items: [
            DropdownMenuItem(
              value: 'all',
              child: Text(AppI18n.t(context, en: 'All billers', ar: 'كل الجهات')),
            ),
            for (final biller in billerList)
              DropdownMenuItem(value: biller.id, child: Text(biller.name)),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedBillerId = value);
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text(dateLabel)),
            TextButton(
              onPressed: pickDates,
              child: Text(AppI18n.t(context, en: 'Pick dates', ar: 'اختر التواريخ')),
            ),
            if (dateRange != null)
              TextButton(
                onPressed: clearDates,
                child: Text(AppI18n.t(context, en: 'Clear', ar: 'مسح')),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ReportSummaryCard(
              title: AppI18n.t(context, en: 'Total billers', ar: 'إجمالي الجهات'),
              value: '${billerList.length}',
            ),
            ReportSummaryCard(
              title: AppI18n.t(context, en: 'Total payments', ar: 'إجمالي الدفعات'),
              value: '${rows.length}',
            ),
            ReportSummaryCard(
              title: AppI18n.t(context, en: 'Total amount', ar: 'إجمالي المبلغ'),
              value: formatOmr(totalAmount),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (byBiller.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nothing here yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          )
        else ...[
          const Text(
            'Payments per biller',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: [
                  for (var i = 0; i < byBiller.length; i++)
                    PieChartSectionData(
                      value: byBiller.values.elementAt(i).toDouble(),
                      title: byBiller.keys.elementAt(i),
                      color: _chartColors[i % _chartColors.length],
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final pay in rows)
            Card(
              child: ListTile(
                title: Text(pay.billerName),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(pay.createdAt.toLocal())),
                trailing: Text(
                  formatOmr(pay.amountBaisa),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ],
      ),
    );
  }
}
