import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../constants/biller_categories.dart';
import '../models/admin_models.dart';
import '../services/admin_services.dart';
import '../widgets/admin_widgets.dart';
import './biller_form_screen.dart';

// Admin page: list billers, then add, edit, or delete them.
class BillerScreen extends StatefulWidget {
  const BillerScreen({super.key});

  @override
  State<BillerScreen> createState() => _BillerScreenState();
}

class _BillerScreenState extends State<BillerScreen> {
  final _billerService = BillerService();
  List<BillerModel> billerList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadBillers();
  }

  // Downloads billers from Firebase.
  Future<void> loadBillers() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final list = await _billerService.loadBillerList();
      if (!mounted) return;
      setState(() {
        billerList = list;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not load billers. Check Firebase rules.';
      });
    }
  }

  // Opens the add form, then reloads if something was saved.
  Future<void> openAdd() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const BillerFormScreen()),
    );
    if (saved == true) await loadBillers();
  }

  // Opens the edit form with the old data already filled in.
  Future<void> openEdit(BillerModel biller) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => BillerFormScreen(biller: biller)),
    );
    if (saved == true) await loadBillers();
  }

  // Asks "Are you sure?" then deletes the biller.
  Future<void> deleteBiller(BillerModel biller) async {
    final ok = await ConfirmDialog.show(
      context,
      message: 'Delete ${biller.name}?',
    );
    if (!ok) return;
    try {
      await _billerService.deleteBiller(biller.id);
      await loadBillers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(context, en: 'Could not delete this biller.', ar: 'تعذر حذف هذه الجهة.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(errorMessage, textAlign: TextAlign.center),
        ),
      );
    }

    return ResponsiveContent(
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppI18n.t(context, en: 'Billers', ar: 'الجهات'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              ElevatedButton(
                onPressed: openAdd,
                child: Text(AppI18n.t(context, en: 'Add', ar: 'إضافة')),
              ),
            ],
          ),
        ),
        Expanded(
          child: billerList.isEmpty
              ? Center(
                  child: Text(
                    AppI18n.t(context, en: 'Nothing here yet', ar: 'لا يوجد شيء هنا بعد'),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: billerList.length,
                  itemBuilder: (context, index) {
                    final biller = billerList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text(
                          biller.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${localizedBillerCategory(context, biller.category)}\n${biller.accountNumber}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => openEdit(biller),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => deleteBiller(biller),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
      ),
    );
  }
}
