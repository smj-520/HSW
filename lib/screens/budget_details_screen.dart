import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';
import './add_budget_screen.dart';

// Read-only page: limit, used, remaining, date, note, plus Edit and Delete.
class BudgetDetailsScreen extends StatefulWidget {
  const BudgetDetailsScreen({super.key, required this.budget});

  final BudgetModel budget;

  @override
  State<BudgetDetailsScreen> createState() => _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends State<BudgetDetailsScreen> {
  final _budgetService = BudgetService();
  late BudgetModel budget;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    budget = widget.budget;
    loadFresh();
  }

  String? sessionUid() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Reloads this budget so Used matches the latest expenses.
  Future<void> loadFresh() async {
    final uid = sessionUid();
    if (uid == null) {
      setState(() => isLoading = false);
      return;
    }
    setState(() => isLoading = true);
    try {
      final fresh = await _budgetService.loadOneBudget(uid: uid, id: budget.id);
      if (!mounted) return;
      if (fresh == null) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        budget = fresh;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // Opens the edit form, then reloads this page (does not close details).
  Future<void> openEdit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(budget: budget),
      ),
    );
    await loadFresh();
  }

  // Asks first, then deletes and goes back to the Budget list.
  Future<void> deleteBudget() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppI18n.t(
              context,
              en: 'Are you sure you want to delete this budget?',
              ar: 'هل أنت متأكد أنك تريد حذف هذه الميزانية؟',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppI18n.t(context, en: 'Cancel', ar: 'إلغاء')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppI18n.t(context, en: 'Delete', ar: 'حذف'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final uid = sessionUid();
    if (uid == null) return;
    try {
      await _budgetService.deleteBudget(uid: uid, id: budget.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppI18n.t(context, en: 'Budget deleted', ar: 'تم حذف الميزانية'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(context, en: 'Could not delete this budget.', ar: 'تعذر حذف هذه الميزانية.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = findBudgetCategory(budget.category);
    final used = budget.usedAmountBaisa;
    final limit = budget.amountBaisa;
    final remaining = budget.remainingBaisa;
    final percent = limit <= 0 ? 0.0 : used / limit;
    final Color barColor;
    if (percent > 1) {
      barColor = Colors.red;
    } else if (percent >= 0.8) {
      barColor = Colors.orange;
    } else {
      barColor = const Color(0xFF27AE60);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F0),
        centerTitle: true,
        title: Text(AppI18n.t(context, en: 'Budget Details', ar: 'تفاصيل الميزانية')),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)))
            : ResponsiveContent(
              child: ListView(
                padding: EdgeInsets.all(responsivePagePaddingX(MediaQuery.sizeOf(context).width).clamp(16, 28)),
                children: [
                  Row(
                    children: [
                      Icon(cat?.icon ?? Icons.apps_outlined, size: 40),
                      const SizedBox(width: 12),
                      Text(
                        cat == null
                            ? AppI18n.t(context, en: 'Overall', ar: 'الإجمالي')
                            : localizedBudgetCategoryName(context, cat.id),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _line(AppI18n.t(context, en: 'Budget limit', ar: 'حد الميزانية'), formatBudgetOmr(limit)),
                  _line(AppI18n.t(context, en: 'Used', ar: 'المستخدم'), formatBudgetOmr(used)),
                  _line(
                    AppI18n.t(context, en: 'Remaining', ar: 'المتبقي'),
                    formatBudgetOmr(remaining < 0 ? 0 : remaining),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent > 1 ? 1 : percent,
                      minHeight: 10,
                      color: barColor,
                      backgroundColor: const Color(0xFFE8E8E8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _line(
                    AppI18n.t(context, en: 'Date', ar: 'التاريخ'),
                    budget.date == null
                        ? AppI18n.t(context, en: 'No date', ar: 'بدون تاريخ')
                        : DateFormat('yyyy-MM-dd').format(budget.date!),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppI18n.t(context, en: 'Note', ar: 'ملاحظة'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    budget.note.trim().isEmpty
                        ? AppI18n.t(context, en: 'No note', ar: 'لا توجد ملاحظة')
                        : budget.note,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: openEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      AppI18n.t(context, en: 'Edit', ar: 'تعديل'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: deleteBudget,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      AppI18n.t(context, en: 'Delete', ar: 'حذف'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
