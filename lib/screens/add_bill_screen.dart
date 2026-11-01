import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../utils/formatters.dart';
import '../services/bill_service.dart';

// Form to add one unpaid bill. The user types every value. Nothing is pre-filled.
class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _billService = BillService();
  DateTime? selectedDueDate;
  bool isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String? sessionUid() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Opens the calendar so the user can pick a due date.
  Future<void> pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => selectedDueDate = picked);
  }

  // Checks name, amount, and due date, then saves an unpaid bill.
  Future<void> saveBill() async {
    final name = _name.text.trim();
    final amountBaisa = parseOmrToBaisa(_amount.text);
    if (name.isEmpty) {
      setState(() => errorMessage = 'Enter a bill name');
      return;
    }
    if (amountBaisa == null) {
      setState(() => errorMessage = 'Enter an amount greater than 0');
      return;
    }
    if (selectedDueDate == null) {
      setState(() => errorMessage = 'Select a due date');
      return;
    }
    final uid = sessionUid();
    if (uid == null) {
      setState(() => errorMessage = 'You must be signed in.');
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      await _billService.addBill(
        uid: uid,
        name: name,
        amountBaisa: amountBaisa,
        dueDate: selectedDueDate!,
        note: _note.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(content: Text(AppI18n.t(context, en: 'Bill saved', ar: 'تم حفظ الفاتورة'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not save. Check Firebase rules.';
      });
    }
  }

  InputDecoration fieldLook({String? hint, String? counter}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      counterText: counter,
      hintStyle: const TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF27AE60), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F0),
        centerTitle: true,
        title: Text(AppI18n.t(context, en: 'Add Bill', ar: 'إضافة فاتورة')),
      ),
      body: SafeArea(
        child: ResponsiveContent(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            responsivePagePaddingX(MediaQuery.sizeOf(context).width),
            8,
            responsivePagePaddingX(MediaQuery.sizeOf(context).width),
            24,
          ),
          children: [
            Text(AppI18n.t(context, en: 'Bill Name', ar: 'اسم الفاتورة'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              enabled: !isLoading,
              decoration: fieldLook(hint: AppI18n.t(context, en: 'Enter bill name', ar: 'أدخل اسم الفاتورة')),
            ),
            const SizedBox(height: 20),
            Text(AppI18n.t(context, en: 'Amount', ar: 'المبلغ'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              enabled: !isLoading,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: fieldLook(hint: AppI18n.t(context, en: 'Enter amount', ar: 'أدخل المبلغ')),
            ),
            const SizedBox(height: 20),
            Text(AppI18n.t(context, en: 'Due Date', ar: 'تاريخ الاستحقاق'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: isLoading ? null : pickDueDate,
              child: InputDecorator(
                decoration: fieldLook(
                  hint: AppI18n.t(context, en: 'Select due date', ar: 'اختر تاريخ الاستحقاق'),
                ),
                child: Text(
                  selectedDueDate == null
                      ? AppI18n.t(context, en: 'Select due date', ar: 'اختر تاريخ الاستحقاق')
                      : DateFormat('d MMM yyyy').format(selectedDueDate!),
                  style: TextStyle(
                    color: selectedDueDate == null ? Colors.grey : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(AppI18n.t(context, en: 'Note (optional)', ar: 'ملاحظة (اختياري)'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              enabled: !isLoading,
              maxLength: 100,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: fieldLook(
                hint: AppI18n.t(context, en: 'Add a note...', ar: 'أضف ملاحظة...'),
                counter: '${_note.text.length}/100',
              ),
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(errorMessage, style: const TextStyle(color: Color(0xFFE74C3C))),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        AppI18n.t(context, en: 'Save Bill', ar: 'حفظ الفاتورة'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
