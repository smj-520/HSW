import 'package:flutter/material.dart';

import '../constants/biller_categories.dart';
import '../models/admin_models.dart';
import '../services/admin_services.dart';
import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';

class BillerFormScreen extends StatefulWidget {
  const BillerFormScreen({super.key, this.biller});

  final BillerModel? biller;

  @override
  State<BillerFormScreen> createState() => _BillerFormScreenState();
}

class _BillerFormScreenState extends State<BillerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _accountNumber = TextEditingController();
  final _billerService = BillerService();
  String? _categoryId;
  bool isLoading = false;
  String errorMessage = '';

  bool get isEdit => widget.biller != null;

  @override
  void initState() {
    super.initState();
    final old = widget.biller;
    if (old != null) {
      _name.text = old.name;
      _accountNumber.text = old.accountNumber;
      _categoryId = resolveBillerCategoryId(old.category);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _accountNumber.dispose();
    super.dispose();
  }

  Future<void> saveBiller() async {
    setState(() => errorMessage = '');
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      setState(() {
        errorMessage = AppI18n.t(
          context,
          en: 'Please enter a name, select a category, and fill the account number.',
          ar: 'يرجى إدخال الاسم واختيار الفئة ورقم الحساب.',
        );
      });
      return;
    }
    setState(() => isLoading = true);
    try {
      final String? error;
      if (isEdit) {
        error = await _billerService.updateBiller(
          id: widget.biller!.id,
          name: _name.text,
          category: _categoryId ?? '',
          accountNumber: _accountNumber.text,
        );
      } else {
        error = await _billerService.addBiller(
          name: _name.text,
          category: _categoryId ?? '',
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          isEdit
              ? AppI18n.t(context, en: 'Edit Biller', ar: 'تعديل الجهة')
              : AppI18n.t(context, en: 'Add Biller', ar: 'إضافة جهة'),
        ),
      ),
      body: ResponsiveContent(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(
              responsivePagePaddingX(MediaQuery.sizeOf(context).width)
                  .clamp(16.0, 28.0),
            ),
            children: [
              TextFormField(
                controller: _name,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: AppI18n.t(context, en: 'Name', ar: 'الاسم'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppI18n.t(
                      context,
                      en: 'Name is required',
                      ar: 'الاسم مطلوب',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_categoryId ?? 'category-empty'),
                initialValue: _categoryId,
                isExpanded: true,
                dropdownColor: Theme.of(context).cardColor,
                decoration: InputDecoration(
                  labelText: AppI18n.t(context, en: 'Category', ar: 'الفئة'),
                ),
                hint: Text(
                  AppI18n.t(context, en: 'Select category', ar: 'اختر الفئة'),
                ),
                items: [
                  for (final option in kBillerCategories)
                    DropdownMenuItem(
                      value: option.id,
                      child: Text(
                        AppI18n.t(context, en: option.en, ar: option.ar),
                      ),
                    ),
                ],
                onChanged: isLoading
                    ? null
                    : (id) => setState(() => _categoryId = id),
                validator: (value) {
                  if (value == null || !isAllowedBillerCategory(value)) {
                    return AppI18n.t(
                      context,
                      en: 'Please select a category',
                      ar: 'يرجى اختيار فئة',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumber,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: AppI18n.t(
                    context,
                    en: 'Account number',
                    ar: 'رقم الحساب',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppI18n.t(
                      context,
                      en: 'Account number is required',
                      ar: 'رقم الحساب مطلوب',
                    );
                  }
                  return null;
                },
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
      ),
    );
  }
}
