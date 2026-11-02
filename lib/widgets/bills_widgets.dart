import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bill_model.dart';
import '../services/app_i18n.dart';
import '../utils/formatters.dart';

// White rounded search box. Filters bills by name as the user types.
class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).cardColor,
        hintText: AppI18n.t(context, en: 'Search bills', ar: 'ابحث في الفواتير'),
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ),
    );
  }
}

// One paid bill card: name, paid date, amount in green, Paid check.
class PaidBillCard extends StatelessWidget {
  const PaidBillCard({super.key, required this.bill});

  final BillModel bill;

  @override
  Widget build(BuildContext context) {
    final paid = bill.paidDate ?? bill.dueDate;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppI18n.t(context, en: 'Paid on', ar: 'دُفعت في')} : ${DateFormat('d MMM', AppI18n.isArabic(context) ? 'ar' : 'en').format(paid)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  formatOmr(bill.amountBaisa),
                  style: const TextStyle(
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 22),
              const SizedBox(height: 2),
              Text(
                AppI18n.t(context, en: 'Paid', ar: 'مدفوعة'),
                style: const TextStyle(
                  color: Color(0xFF27AE60),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// One unpaid bill card: name, due date, amount in red, Mark Paid button.
class UnpaidBillCard extends StatelessWidget {
  const UnpaidBillCard({
    super.key,
    required this.bill,
    this.onMarkPaid,
  });

  final BillModel bill;
  final VoidCallback? onMarkPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppI18n.t(context, en: 'Due', ar: 'الاستحقاق')}: ${DateFormat('d MMM', AppI18n.isArabic(context) ? 'ar' : 'en').format(bill.dueDate)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  formatOmr(bill.amountBaisa),
                  style: const TextStyle(
                    color: Color(0xFFE74C3C),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          if (onMarkPaid != null)
            TextButton(
              onPressed: onMarkPaid,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                AppI18n.t(context, en: 'Mark Paid', ar: 'تعليم كمدفوعة'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
