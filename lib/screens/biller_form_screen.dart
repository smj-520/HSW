import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../models/admin_models.dart';
import '../services/admin_services.dart';

// Form used for both Add and Edit. If biller is null, we are adding.
class BillerFormScreen extends StatefulWidget {
  const BillerFormScreen({super.key, this.biller});

  final BillerModel? biller;

  @override
  State<BillerFormScreen> createState() => _BillerFormScreenState();
}

class _BillerFormScreenState extends State<BillerFormScreen> {
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _accountNumber = TextEditingController();
  final _billerService = BillerService();
  bool isLoading = false;
  String errorMessage = '';

  bool get isEdit => widget.biller != null;

  @override
  void initState() {
    super.initState();
    // If we are editing, fill the boxes with the old data.
    final old = widget.biller;
    if (old != null) {
      _name.text = old.name;
      _category.text = old.category;
      _accountNumber.text = old.accountNumber;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _accountNumber.dispose();
    super.dispose();
  }

  // Saves a new biller or updates the old one.
  Future<void> saveBiller() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final String? error;
      if (isEdit) {
        error = await _billerService.updateBiller(
          id: widget.biller!.id,
          name: _name.text,
          category: _category.text,
          accountNumber: _accountNumber.text,
        );
      } else {
        error = await _billerService.addBiller(
          name: _name.text,
          category: _category.text,
          accountNumber: _accountNumber.text,
        );
      }
      if (!mounted) return;
      if (error != null) {
        final text = error;
        setState(() {
          isLoading = false;
          errorMessage = text;
        });
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not save. Check Firebase rules.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F0),
        title: Text(
          isEdit
              ? AppI18n.t(context, en: 'Edit Biller', ar: 'تعديل الجهة')
              : AppI18n.t(context, en: 'Add Biller', ar: 'إضافة جهة'),
        ),
      ),
      body: ResponsiveContent(
      child: ListView(
        padding: EdgeInsets.all(responsivePagePaddingX(MediaQuery.sizeOf(context).width).clamp(16, 28)),
        children: [
          TextField(
            controller: _name,
            enabled: !isLoading,
            decoration: InputDecoration(labelText: AppI18n.t(context, en: 'Name', ar: 'الاسم')),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _category,
            enabled: !isLoading,
            decoration: InputDecoration(labelText: AppI18n.t(context, en: 'Category', ar: 'الفئة')),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _accountNumber,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: AppI18n.t(context, en: 'Account number', ar: 'رقم الحساب'),
            ),
          ),
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(errorMessage, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : saveBiller,
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isEdit
                        ? AppI18n.t(context, en: 'Update', ar: 'تحديث')
                        : AppI18n.t(context, en: 'Add', ar: 'إضافة'),
                  ),
          ),
        ],
      ),
      ),
    );
  }
}
