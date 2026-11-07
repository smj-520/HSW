import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';



import '../constants/biller_categories.dart';
import '../core/money.dart';
import '../models/admin_models.dart';
import '../services/admin_services.dart';
import '../services/app_i18n.dart';
import '../services/bill_service.dart';
import '../utils/admin_logic.dart';
import '../utils/app_messages.dart';
import '../utils/wallet_tc_logic.dart';
import '../widgets/category_icon.dart';
import '../widgets/responsive_layout.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _billerService = BillerService();
  final _billService = BillService();
  DateTime? _due;
  String? _categoryId;
  bool isLoading = false;
  String errorMessage = '';
  List<BillerModel> _allBillers = [];
  Set<String> _adminUids = {};
  String? selectedBillerId;
  StreamSubscription<List<BillerModel>>? _billerSub;

  @override
  void initState() {
    super.initState();
    _loadAdminUids();
    _billerSub = _billerService.watchBillerList().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _allBillers = list;
          if (selectedBillerId != null &&
              !visibleBillers.any((b) => b.id == selectedBillerId)) {
            selectedBillerId = null;
          }
        });
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _billerSub?.cancel();
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  String? sessionUid() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  List<BillerModel> get visibleBillers {
    final uid = sessionUid() ?? '';
    return _billerService.visibleToStudent(
      _allBillers,
      uid,
      adminUids: _adminUids,
    );
  }

  Future<void> _loadAdminUids() async {
    try {
      final users = await AdminUserService().loadUserList();
      if (!mounted) return;
      setState(() {
        _adminUids = {
          for (final user in users)
            if (user.isAdmin) user.uid,
        };
      });
    } catch (_) {}
  }

  String? _linkedBillerId(String name, String? category) {
    if (selectedBillerId != null) return selectedBillerId;
    final key = normalizeBillerName(name);
    final cat = (category ?? '').trim().toLowerCase();
    for (final biller in visibleBillers) {
      if (normalizeBillerName(biller.name) != key) continue;
      if (cat.isEmpty ||
          biller.category.trim().toLowerCase() == cat ||
          resolveBillerCategoryId(biller.category) == category) {
        return biller.id;
      }
    }
    return null;
  }

  InputDecoration fieldLook({String? hint, String? label}) {
    return InputDecoration(
      filled: true,
      fillColor: Theme.of(context).cardColor,
      hintText: hint,
      labelText: label,
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

  void pickBiller(String? id) {
    setState(() => selectedBillerId = id);
    if (id == null) return;
    for (final biller in visibleBillers) {
      if (biller.id == id) {
        _name.text = biller.name;
        _categoryId = resolveBillerCategoryId(biller.category);
        break;
      }
    }
  }

  Future<void> pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> saveBill() async {
    final name = _name.text.trim();
    final category = _categoryId;
    final fieldError = addBillFieldError(
      name: name,
      amountRaw: _amount.text,
      dueDate: _due,
      category: category,
    );
    if (fieldError != null) {
      setState(() => errorMessage = fieldError);
      return;
    }
    final parsed = Money.omrToBaisa(_amount.text);
    if (!parsed.ok) {
      setState(() => errorMessage = parsed.error ?? AppMessages.amountGreaterThanZero);
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
        amountBaisa: parsed.baisa!,
        dueDate: _due!,
        billerId: _linkedBillerId(name, category),
        category: category,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppI18n.t(context, en: 'Bill saved', ar: 'تم حفظ الفاتورة')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('ArgumentError: ', '');
      });
    }
  }

  List<DropdownMenuItem<String>> categoryItems() {
    return [
      for (final option in kBillerCategories)
        DropdownMenuItem(
          value: option.id,
          child: Row(
            children: [
              CategoryIcon(option.id, categoryTileColor(option.id), 28),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  AppI18n.t(context, en: option.en, ar: option.ar),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final billers = visibleBillers;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              Text(
                AppI18n.t(context, en: 'Biller name', ar: 'اسم الجهة'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (billers.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('${selectedBillerId ?? 'none'}-${billers.length}'),
                  initialValue: selectedBillerId,
                  isExpanded: true,
                  decoration: fieldLook(
                    hint: AppI18n.t(context, en: 'Pick a biller', ar: 'اختر جهة'),
                  ),
                  items: [
                    for (final biller in billers)
                      DropdownMenuItem(
                        value: biller.id,
                        child: Text(biller.name),
                      ),
                  ],
                  onChanged: isLoading ? null : pickBiller,
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _name,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: fieldLook(
                  hint: AppI18n.t(context, en: 'Biller name', ar: 'اسم الجهة'),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppI18n.t(context, en: 'Category', ar: 'الفئة'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey(_categoryId ?? 'category-empty'),
                initialValue: _categoryId,
                isExpanded: true,
                decoration: fieldLook(
                  hint: AppI18n.t(context, en: 'Select category', ar: 'اختر الفئة'),
                ),
                items: categoryItems(),
                onChanged: isLoading
                    ? null
                    : (id) => setState(() => _categoryId = id),
              ),
              const SizedBox(height: 20),
              Text(
                AppI18n.t(context, en: 'Due date', ar: 'تاريخ الاستحقاق'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ListTile(
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  _due == null
                      ? AppI18n.t(
                          context,
                          en: 'Select due date',
                          ar: 'اختر تاريخ الاستحقاق',
                        )
                      : DateFormat('yyyy-MM-dd').format(_due!),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: isLoading ? null : pickDue,
              ),
              const SizedBox(height: 20),
              Text(
                AppI18n.t(context, en: 'Amount', ar: 'المبلغ'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                enabled: !isLoading,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: fieldLook(
                  hint: AppI18n.t(context, en: 'Enter amount', ar: 'أدخل المبلغ'),
                ),
              ),
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Color(0xFFE74C3C)),
                ),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppI18n.t(context, en: 'Save', ar: 'حفظ'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
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
