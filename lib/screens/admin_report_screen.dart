import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../utils/formatters.dart';
import '../models/admin_models.dart';
import '../models/bill_model.dart';
import '../services/admin_services.dart';
import '../utils/admin_logic.dart';
import '../utils/app_messages.dart';
import '../services/pdf_service.dart';
import '../widgets/admin_widgets.dart';


class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  final _reportService = ReportService();
  final _billerService = BillerService();
  final _pdfService = PdfService();
  bool isLoading = true;
  String errorMessage = '';
  List<BillerModel> billerList = [];
  List<PaymentModel> paymentList = [];
  List<BillModel> billList = [];
  String selectedBillerId = 'all';
  DateTimeRange? dateRange;
  bool generated = false;
  String reportBillerId = 'all';
  DateTimeRange? reportRange;
  String generateMessage = '';

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

  Future<void> loadReport() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final billers = await _billerService.loadBillerList();
      var payments = <PaymentModel>[];
      try {
        payments = await _reportService.loadPaymentList();
      } catch (_) {}
      var bills = <BillModel>[];
      try {
        bills = await _reportService.loadAllBillerBills();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        billerList = billers;
        paymentList = payments;
        billList = bills;
        if (selectedBillerId != 'all' &&
            !billers.any((biller) => biller.id == selectedBillerId)) {
          selectedBillerId = 'all';
        }
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

  Future<void> pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDateRange: dateRange,
    );
    if (picked != null) {
      setState(() => dateRange = picked);
    }
  }

  void clearDates() {
    setState(() => dateRange = null);
  }

  Future<void> generateReport() async {
    if (dateRange == null) {
      setState(() {
        generated = false;
        generateMessage = AppI18n.t(
          context,
          en: 'Please pick a date range',
          ar: 'يرجى اختيار فترة زمنية',
        );
      });
      return;
    }
    await loadReport();
    if (!mounted) return;
    setState(() {
      generated = true;
      generateMessage = '';
      reportBillerId = selectedBillerId;
      reportRange = dateRange;
    });
  }

  bool _billBelongsToSelected(BillModel bill) {
    if (reportBillerId == 'all') return true;
    if (bill.billerId == reportBillerId) return true;
    final wanted = _billerLabel(reportBillerId, '').trim().toLowerCase();
    if (wanted.isEmpty || wanted == 'unknown') return false;
    return bill.name.trim().toLowerCase() == wanted;
  }

  List<BillModel> filteredBills() {
    if (!generated || reportRange == null) return [];
    final inRange = filterBillsForBillerReport(
      bills: billList,
      billerIdOrAll: reportBillerId,
      start: reportRange!.start,
      end: reportRange!.end,
    );
    if (inRange.isNotEmpty) {
      return [for (final bill in inRange) if (_billBelongsToSelected(bill)) bill];
    }
    return [for (final bill in billList) if (_billBelongsToSelected(bill)) bill];
  }

  List<PaymentModel> filteredPayments() {
    if (!generated || reportRange == null) return [];
    return paymentList.where((pay) {
      if (reportBillerId != 'all' && pay.billerId != reportBillerId) {
        return false;
      }
      final day = DateTime(pay.createdAt.year, pay.createdAt.month, pay.createdAt.day);
      final start = DateTime(
        reportRange!.start.year,
        reportRange!.start.month,
        reportRange!.start.day,
      );
      final end = DateTime(
        reportRange!.end.year,
        reportRange!.end.month,
        reportRange!.end.day,
      );
      if (day.isBefore(start) || day.isAfter(end)) return false;
      return true;
    }).toList();
  }

  String _billerLabel(String? billerId, String fallback) {
    for (final biller in billerList) {
      if (biller.id == billerId) return biller.name;
    }
    return fallback.isEmpty ? 'Unknown' : fallback;
  }

  Future<void> downloadGeneratedReport({
    required bool oneBiller,
    required int totalAmount,
    required int rowCount,
    required Map<String, int> byBiller,
    required List<BillModel> billRows,
    required List<PaymentModel> payRows,
    required bool useBills,
  }) async {
    if (!generated || reportRange == null) return;
    final hasData = rowCount > 0 || totalAmount > 0;
    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.noDataToDownload)),
      );
      return;
    }
    final period =
        '${DateFormat('yyyy-MM-dd').format(reportRange!.start)} → ${DateFormat('yyyy-MM-dd').format(reportRange!.end)}';
    var billerLabel = AppI18n.t(context, en: 'All billers', ar: 'كل الجهات');
    if (oneBiller) {
      billerLabel = _billerLabel(reportBillerId, reportBillerId);
    }
    final lines = <BillerReportLine>[];
    if (useBills) {
      for (final bill in billRows) {
        lines.add(
          BillerReportLine(
            name: bill.name,
            date: bill.dueDate,
            amountBaisa: bill.amountBaisa,
          ),
        );
      }
    } else {
      for (final pay in payRows) {
        lines.add(
          BillerReportLine(
            name: _billerLabel(pay.billerId, pay.billerName),
            date: pay.createdAt.toLocal(),
            amountBaisa: pay.amountBaisa,
          ),
        );
      }
    }
    final error = await _pdfService.downloadBillerReport(
      period: period,
      billerLabel: billerLabel,
      totalAmount: totalAmount,
      billCount: rowCount,
      totalsByBiller: byBiller,
      lines: lines,
      allBillers: !oneBiller,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppI18n.t(context, en: 'Report downloaded', ar: 'تم تنزيل التقرير')),
      ),
    );
  }

  Map<String, int> totalsForEveryBiller(List<BillModel> bills, List<PaymentModel> pays) {
    final map = <String, int>{
      for (final biller in billerList) biller.name: 0,
    };
    if (bills.isNotEmpty) {
      for (final bill in bills) {
        final label = _billerLabel(bill.billerId, bill.name);
        map[label] = (map[label] ?? 0) + bill.amountBaisa;
      }
    } else {
      for (final pay in pays) {
        final label = _billerLabel(pay.billerId, pay.billerName);
        map[label] = (map[label] ?? 0) + pay.amountBaisa;
      }
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

    final billRows = filteredBills();
    final payRows = filteredPayments();
    final useBills = billRows.isNotEmpty;
    final byBiller = totalsForEveryBiller(billRows, payRows);
    final oneBiller = generated && reportBillerId != 'all';
    var totalAmount = 0;
    for (final n in byBiller.values) {
      totalAmount += n;
    }
    if (oneBiller) {
      totalAmount = 0;
      if (useBills) {
        for (final bill in billRows) {
          totalAmount += bill.amountBaisa;
        }
      } else {
        for (final pay in payRows) {
          totalAmount += pay.amountBaisa;
        }
      }
    }
    final rowCount = useBills ? billRows.length : payRows.length;
    final dateLabel = dateRange == null
        ? AppI18n.t(context, en: 'Pick a date range', ar: 'اختر فترة زمنية')
        : '${DateFormat('yyyy-MM-dd').format(dateRange!.start)} → ${DateFormat('yyyy-MM-dd').format(dateRange!.end)}';
    final pieValues = [
      for (final entry in byBiller.entries)
        if (entry.value > 0) entry,
    ];

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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: generateReport,
            child: Text(AppI18n.t(context, en: 'Generate', ar: 'إنشاء')),
          ),
        ),
        if (generateMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(generateMessage, style: const TextStyle(color: Colors.red)),
        ],
        if (!generated)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                AppI18n.t(
                  context,
                  en: 'Select a biller and a date range, then tap Generate.',
                  ar: 'اختر جهة وفترة زمنية ثم اضغط إنشاء.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          )
        else ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (!oneBiller)
                ReportSummaryCard(
                  title: AppI18n.t(context, en: 'Total billers', ar: 'إجمالي الجهات'),
                  value: '${billerList.length}',
                ),
              ReportSummaryCard(
                title: AppI18n.t(context, en: 'Total bills', ar: 'إجمالي الفواتير'),
                value: '$rowCount',
              ),
              ReportSummaryCard(
                title: AppI18n.t(context, en: 'Total amount', ar: 'إجمالي المبلغ'),
                value: formatOmr(totalAmount),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (oneBiller) ...[
            Text(
              AppI18n.t(context, en: 'Bills', ar: 'الفواتير'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (rowCount == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    AppI18n.t(context, en: 'Nothing here yet', ar: 'لا يوجد شيء هنا بعد'),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else if (useBills)
              for (final bill in billRows)
                Card(
                  child: ListTile(
                    title: Text(bill.name),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(bill.dueDate)),
                    trailing: Text(
                      formatOmr(bill.amountBaisa),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                )
            else
              for (final pay in payRows)
                Card(
                  child: ListTile(
                    title: Text(_billerLabel(pay.billerId, pay.billerName)),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(pay.createdAt.toLocal())),
                    trailing: Text(
                      formatOmr(pay.amountBaisa),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
          ] else ...[
            Text(
              AppI18n.t(context, en: 'Total for every biller', ar: 'الإجمالي لكل جهة'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            for (final entry in byBiller.entries)
              Card(
                child: ListTile(
                  title: Text(entry.key),
                  trailing: Text(
                    formatOmr(entry.value),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            if (pieValues.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    sections: [
                      for (var i = 0; i < pieValues.length; i++)
                        PieChartSectionData(
                          value: pieValues[i].value.toDouble(),
                          title: totalAmount <= 0
                              ? ''
                              : '${((pieValues[i].value / totalAmount) * 100).round()}%',
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
            ],
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => downloadGeneratedReport(
                oneBiller: oneBiller,
                totalAmount: totalAmount,
                rowCount: rowCount,
                byBiller: byBiller,
                billRows: billRows,
                payRows: payRows,
                useBills: useBills,
              ),
              child: Text(
                AppI18n.t(context, en: 'Download Report', ar: 'تنزيل التقرير'),
              ),
            ),
          ),
        ],
      ],
      ),
    );
  }
}
