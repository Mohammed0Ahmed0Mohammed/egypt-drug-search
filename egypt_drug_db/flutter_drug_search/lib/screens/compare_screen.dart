import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/drug_provider.dart';
import '../model/drug.dart';

/// Compare two selected drugs side by side: price / company / ingredient / form.
class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DrugProvider>();
    final drugs = prov.getCompareDrugs();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مقارنة دواءين'),
          actions: [
            TextButton(
              onPressed: prov.clearCompare,
              child: const Text('إلغاء'),
            ),
          ],
        ),
        body: drugs.length < 2
            ? const Center(
                child: Text('اختر دواءين للمقارنة من شاشة البحث'),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _headers(drugs),
                  const SizedBox(height: 16),
                  _row('السعر', drugs[0].priceLabel, drugs[1].priceLabel,
                      highlight: _cheaper(drugs[0].priceEgp, drugs[1].priceEgp)),
                  _row('الشركة المصنعة',
                      drugs[0].manufacturer.isNotEmpty ? drugs[0].manufacturer : '—',
                      drugs[1].manufacturer.isNotEmpty ? drugs[1].manufacturer : '—'),
                  _row('المادة الفعالة',
                      drugs[0].scientificName.isNotEmpty ? drugs[0].scientificName : '—',
                      drugs[1].scientificName.isNotEmpty ? drugs[1].scientificName : '—'),
                  _row('الشكل الصيدلي', drugs[0].category, drugs[1].category),
                  _row('المجموعة العلاجية',
                      drugs[0].therapyClass.isNotEmpty ? drugs[0].therapyClass : '—',
                      drugs[1].therapyClass.isNotEmpty ? drugs[1].therapyClass : '—'),
                  _row('طريق الاستخدام', drugs[0].route, drugs[1].route),
                ],
              ),
      ),
    );
  }

  Widget _headers(List<Drug> drugs) {
    return Row(
      children: [
        Expanded(child: _head(drugs[0].displayName)),
        const SizedBox(width: 12),
        Expanded(child: _head(drugs[1].displayName)),
      ],
    );
  }

  Widget _head(String t) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(t,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _row(String label, String a, String b, {int highlight = 0}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _cell(a, highlight == 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _cell(b, highlight == 2),
          ),
          SizedBox(
            width: 96,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, bool highlight) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: highlight ? Colors.green.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          color: highlight ? Colors.green.shade800 : null,
        ),
      ),
    );
  }

  /// Returns 1 if [a] cheaper, 2 if [b] cheaper, 0 if tie/unknown.
  int _cheaper(double? a, double? b) {
    if (a == null || b == null) return 0;
    if (a < b) return 1;
    if (b < a) return 2;
    return 0;
  }
}
