import 'dart:io';

import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

import './app_i18n.dart';
import '../utils/app_messages.dart';
import '../utils/formatters.dart';
import '../utils/wallet_tc_logic.dart';
import '../models/report_model.dart';
import '../widgets/report_widgets.dart';

class PdfService {
  Future<String?> downloadReport(ReportModel report) async {
    final blocked = downloadReportError(
      hasData: report.hasData,
      storageAllowed: true,
    );
    if (blocked != null) return blocked;
    try {
      final permission = await Permission.storage.request();
      if (permission.isPermanentlyDenied) {
        return AppMessages.permissionRequired;
      }
      final title = report.isWeekly
          ? AppI18n.ts(en: 'Weekly Financial Report', ar: 'التقرير المالي الأسبوعي')
          : AppI18n.ts(en: 'Monthly Financial Report', ar: 'التقرير المالي الشهري');
      final period = report.isWeekly
          ? weekPeriodLabel(report.startDate, report.endDate)
          : monthPeriodLabel(report.startDate);
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (context) {
            return [
              pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('${AppI18n.ts(en: 'Period', ar: 'الفترة')}: $period'),
              pw.SizedBox(height: 16),
              pw.Text('${AppI18n.ts(en: 'Total income', ar: 'إجمالي الدخل')}: ${formatOmr(report.totalIncome)}'),
              pw.Text('${AppI18n.ts(en: 'Total expenses', ar: 'إجمالي المصروفات')}: ${formatOmr(report.totalExpense)}'),
              pw.Text('${AppI18n.ts(en: 'Balance', ar: 'الرصيد')}: ${formatOmr(report.balance)}'),
              pw.Text('${AppI18n.ts(en: 'Savings', ar: 'الادخار')}: ${formatOmr(report.totalSaving)}'),
              pw.SizedBox(height: 16),
              pw.Text(
                AppI18n.ts(en: 'Expenses by category', ar: 'المصروفات حسب الفئة'),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              if (report.categoryTotals.isEmpty)
                pw.Text(AppI18n.ts(en: 'No expenses in this period', ar: 'لا مصروفات في هذه الفترة'))
              else
                for (final item in report.categoryTotals)
                  pw.Text(
                    '${item.name}: ${formatOmr(item.amountBaisa)} (${(item.percent * 100).round()}%)',
                  ),
              pw.SizedBox(height: 16),
              pw.Text(
                AppI18n.ts(en: 'Transactions', ar: 'المعاملات'),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              for (final tx in report.transactions)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '${DateFormat('yyyy-MM-dd').format(tx.date.toLocal())}  ${tx.title}  (${tx.type})  ${formatOmr(tx.amountBaisa)}',
                  ),
                ),
            ];
          },
        ),
      );
      final bytes = await doc.save();
      final filename = report.isWeekly
          ? 'weekly-financial-report.pdf'
          : 'monthly-financial-report.pdf';
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return null;
    } catch (e) {
      return 'Could not download the report.';
    }
  }

  Future<String?> downloadBillerReport({
    required String period,
    required String billerLabel,
    required int totalAmount,
    required int billCount,
    required Map<String, int> totalsByBiller,
    required List<BillerReportLine> lines,
    required bool allBillers,
  }) async {
    final hasData = billCount > 0 || totalAmount > 0 || totalsByBiller.values.any((n) => n > 0);
    final blocked = downloadReportError(hasData: hasData, storageAllowed: true);
    if (blocked != null) return blocked;
    try {
      final permission = await Permission.storage.request();
      if (permission.isPermanentlyDenied) {
        return AppMessages.permissionRequired;
      }
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (context) {
            return [
              pw.Text(
                AppI18n.ts(en: 'Billers Report', ar: 'تقرير الجهات'),
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text('${AppI18n.ts(en: 'Period', ar: 'الفترة')}: $period'),
              pw.Text('${AppI18n.ts(en: 'Biller', ar: 'الجهة')}: $billerLabel'),
              pw.Text('${AppI18n.ts(en: 'Total bills', ar: 'إجمالي الفواتير')}: $billCount'),
              pw.Text('${AppI18n.ts(en: 'Total amount', ar: 'إجمالي المبلغ')}: ${formatOmr(totalAmount)}'),
              if (allBillers) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  AppI18n.ts(en: 'Total for every biller', ar: 'الإجمالي لكل جهة'),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                for (final entry in totalsByBiller.entries)
                  pw.Text('${entry.key}: ${formatOmr(entry.value)}'),
              ],
              if (lines.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  AppI18n.ts(en: 'Bills', ar: 'الفواتير'),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                for (final line in lines)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '${DateFormat('yyyy-MM-dd').format(line.date)}  ${line.name}  ${formatOmr(line.amountBaisa)}',
                    ),
                  ),
              ],
            ];
          },
        ),
      );
      final bytes = await doc.save();
      const filename = 'billers-report.pdf';
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return null;
    } catch (e) {
      return 'Could not download the report.';
    }
  }
}

class BillerReportLine {
  const BillerReportLine({
    required this.name,
    required this.date,
    required this.amountBaisa,
  });

  final String name;
  final DateTime date;
  final int amountBaisa;
}
