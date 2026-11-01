import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import './app_i18n.dart';
import '../utils/formatters.dart';
import '../models/report_model.dart';
import '../widgets/report_widgets.dart';

// Builds a PDF from a report and opens the share / save sheet.
class PdfService {
  // Creates the PDF. Returns an error text, or null on success.
  Future<String?> downloadReport(ReportModel report) async {
    if (!report.hasData) {
      return AppI18n.ts(en: 'No data to download', ar: 'لا توجد بيانات للتنزيل');
    }
    try {
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
      await Printing.sharePdf(
        bytes: bytes,
        filename: report.isWeekly
            ? 'weekly-financial-report.pdf'
            : 'monthly-financial-report.pdf',
      );
      return null;
    } catch (e) {
      return 'Could not download the report.';
    }
  }
}
