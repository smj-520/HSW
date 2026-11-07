import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../services/app_i18n.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../models/report_model.dart';
import '../services/pdf_service.dart';
import '../services/report_service.dart';
import '../widgets/report_widgets.dart';
import '../widgets/transaction_widgets.dart';
import '../widgets/responsive_layout.dart';


class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _reportService = FinanceReportService();
  final _pdfService = PdfService();
  ReportModel? report;
  DateTime weekAnchor = DateTime.now();
  DateTime monthAnchor = DateTime.now();
  bool showWeekly = true;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  String? sessionUid() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }


  Future<void> loadReport() async {
    final uid = sessionUid();
    if (uid == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'You must be signed in.';
      });
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final next = showWeekly
          ? await _reportService.buildWeeklyReport(uid: uid, anchor: weekAnchor)
          : await _reportService.buildMonthlyReport(uid: uid, anchor: monthAnchor);
      if (!mounted) return;
      setState(() {
        report = next;
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

  void pickWeekly() {
    if (showWeekly) return;
    setState(() => showWeekly = true);
    loadReport();
  }

  void pickMonthly() {
    if (!showWeekly) return;
    setState(() => showWeekly = false);
    loadReport();
  }

  void goPrevious() {
    if (showWeekly) {
      setState(() => weekAnchor = weekAnchor.subtract(const Duration(days: 7)));
    } else {
      setState(() => monthAnchor = DateTime(monthAnchor.year, monthAnchor.month - 1, 1));
    }
    loadReport();
  }

  void goNext() {
    if (!canGoNext()) return;
    if (showWeekly) {
      setState(() => weekAnchor = weekAnchor.add(const Duration(days: 7)));
    } else {
      setState(() => monthAnchor = DateTime(monthAnchor.year, monthAnchor.month + 1, 1));
    }
    loadReport();
  }

  bool canGoNext() {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (showWeekly) {
      final nextStart = _reportService.weekStart(weekAnchor.add(const Duration(days: 7)));
      return !nextStart.isAfter(today);
    }
    final nextMonth = DateTime(monthAnchor.year, monthAnchor.month + 1, 1);
    return !nextMonth.isAfter(today);
  }

  String periodLabel(ReportModel report) {
    if (showWeekly) return weekPeriodLabel(report.startDate, report.endDate);
    return monthPeriodLabel(monthAnchor);
  }


  Future<void> downloadReport() async {
    final current = report;
    if (current == null || !current.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppI18n.t(context, en: 'No data to download', ar: 'لا توجد بيانات للتنزيل'))),
      );
      return;
    }
    final error = await _pdfService.downloadReport(current);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppI18n.t(context, en: 'Report downloaded', ar: 'تم تنزيل التقرير'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = report;
    return Material(
      color: FinanceSurface.pageBg(context),
      child: SafeArea(
        child: ResponsiveContent(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: FinancePageTitle(
                    text: AppI18n.t(context, en: 'Report', ar: 'التقرير'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: WeekMonthPills(
                    showWeekly: showWeekly,
                    onWeekly: pickWeekly,
                    onMonthly: pickMonthly,
                  ),
                ),
                if (current != null)
                  PeriodSwitcher(
                    label: periodLabel(current),
                    onPrevious: goPrevious,
                    onNext: goNext,
                    canGoNext: canGoNext(),
                  ),
                Expanded(child: _body(current)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FinancePrimaryButton(
                    label: AppI18n.t(context, en: 'Download Report', ar: 'تنزيل التقرير'),
                    onPressed: isLoading ? null : downloadReport,
                    expand: true,
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _body(ReportModel? report) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)));
    }
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(errorMessage, textAlign: TextAlign.center),
        ),
      );
    }
    if (report == null) {
      return Center(
        child: Text(AppI18n.t(context, en: 'No data for this period yet', ar: 'لا توجد بيانات لهذه الفترة بعد')),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        IncomeExpenseCard(
          incomeBaisa: report.totalIncome,
          expenseBaisa: report.totalExpense,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _miniCard(
                AppI18n.t(context, en: 'Balance', ar: 'الرصيد'),
                formatOmr(report.balance),
                AppColors.homePrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _miniCard(
                AppI18n.t(context, en: 'Savings', ar: 'الادخار'),
                formatOmr(report.totalSaving),
                AppColors.homeSaving,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          AppI18n.t(context, en: 'Expenses by category', ar: 'المصروفات حسب الفئة'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: FinanceSurface.ink(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: FinanceSurface.card(context),
          child: CategoryChart(categoryTotals: report.categoryTotals),
        ),
        const SizedBox(height: 20),
        Text(
          AppI18n.t(context, en: 'Transactions', ar: 'المعاملات'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: FinanceSurface.ink(context),
          ),
        ),
        const SizedBox(height: 8),
        if (!report.hasData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              AppI18n.t(context, en: 'No data for this period yet', ar: 'لا توجد بيانات لهذه الفترة بعد'),
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: FinanceSurface.card(context, radius: 20),
            child: Column(
              children: [
                for (var i = 0; i < report.transactions.length; i++) ...[
                  ReportTransactionRow(transaction: report.transactions[i]),
                  if (i < report.transactions.length - 1)
                    const Divider(height: 1, color: Color(0xFFF0EEE8)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _miniCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: FinanceSurface.card(context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: FinanceSurface.muted(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
