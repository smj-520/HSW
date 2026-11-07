import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../widgets/report_widgets.dart';
import '../widgets/transaction_widgets.dart';
import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';

const _barColors = [
  Color(0xFFE74C3C),
  Color(0xFFF1C40F),
  Color(0xFF3498DB),
  Color(0xFF27AE60),
  Color(0xFF9B59B6),
  Color(0xFFE67E22),
];

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _reportService = FinanceReportService();
  ReportModel? report;
  bool isLoading = true;
  String errorMessage = '';
  bool showWeekly = true;

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
      final now = DateTime.now();
      final next = showWeekly
          ? await _reportService.buildWeeklyReport(uid: uid, anchor: now)
          : await _reportService.buildMonthlyReport(uid: uid, anchor: now);
      if (!mounted) return;
      setState(() {
        report = next;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not load summary. Check Firebase rules.';
      });
    }
  }

  void tapDone() {
    if (widget.onDone != null) {
      widget.onDone!();
      return;
    }
    Navigator.of(context).pop();
  }

  List<CategoryBar> barsFrom(ReportModel report) {
    final bars = <CategoryBar>[];
    for (var i = 0; i < report.categoryTotals.length; i++) {
      final item = report.categoryTotals[i];
      bars.add(
        CategoryBar(
          name: item.name,
          amountBaisa: item.amountBaisa,
          percent: item.percent,
          color: _barColors[i % _barColors.length],
          categoryId: item.id,
        ),
      );
    }
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    final current = report;
    return Material(
      color: FinanceSurface.pageBg(context),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)))
            : errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(errorMessage, textAlign: TextAlign.center),
                    ),
                  )
                : ResponsiveContent(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          const FinancePageTitle(text: 'Summary'),
                          const SizedBox(height: 18),
                          WeekMonthPills(
                            showWeekly: showWeekly,
                            onWeekly: () {
                              setState(() => showWeekly = true);
                              loadReport();
                            },
                            onMonthly: () {
                              setState(() => showWeekly = false);
                              loadReport();
                            },
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppI18n.t(context, en: 'Expenses by category', ar: 'المصروفات حسب الفئة'),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: FinanceSurface.ink(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                            decoration: FinanceSurface.card(context),
                            child: SummaryChart(
                              bars: current == null ? [] : barsFrom(current),
                            ),
                          ),
                          const SizedBox(height: 20),
                          IncomeExpenseCard(
                            incomeBaisa: current?.totalIncome ?? 0,
                            expenseBaisa: current?.totalExpense ?? 0,
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: FinancePrimaryButton(
                              label: AppI18n.t(context, en: 'Done', ar: 'تم'),
                              onPressed: tapDone,
                            ),
                          ),
                        ],
                      ),
                    ),
      ),
    );
  }
}
