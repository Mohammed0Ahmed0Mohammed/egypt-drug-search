import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/drug_provider.dart';
import '../model/drug.dart';

/// Detail screen shown when a drug card is tapped.
/// Shows the drug's fields plus "كل الأشكال" — every dosage form that shares
/// the same active ingredient (useful to compare prices across brands/forms).
class DrugDetailScreen extends StatefulWidget {
  final Drug drug;
  const DrugDetailScreen({super.key, required this.drug});

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
  List<Drug> _forms = [];
  List<Drug> _alternatives = [];
  bool _loadingForms = true;
  bool _loadingAlt = true;

  @override
  void initState() {
    super.initState();
    _loadForms();
    _loadAlternatives();
  }

  Future<void> _loadForms() async {
    final prov = context.read<DrugProvider>();
    _forms = await prov.allFormsOf(
      widget.drug.scientificName,
      tradeNameEn: widget.drug.tradeNameEn,
    );
    if (mounted) setState(() => _loadingForms = false);
  }

  Future<void> _loadAlternatives() async {
    final prov = context.read<DrugProvider>();
    _alternatives = await prov.cheaperAlternativesFor(widget.drug);
    if (mounted) setState(() => _loadingAlt = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.drug;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(d.displayName),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _title(d.displayName),
            if (d.tradeNameEn.isNotEmpty) _subtitle(d.tradeNameEn),
            const SizedBox(height: 16),
            _infoTile('السعر', d.priceLabel),
            _infoTile('الفئة', d.category),
            _infoTile('المجموعة العلاجية', d.therapyClass.isNotEmpty ? d.therapyClass : '—'),
            _infoTile('طريق الاستخدام (route)', d.route.isNotEmpty ? d.route : '—'),
            _infoTile('التصنيف الدوائي', d.drugClass.isNotEmpty ? d.drugClass : '—'),
            _infoTile('الشركة المصنعة', d.manufacturer.isNotEmpty ? d.manufacturer : '—'),
            _infoTile('المادة الفعالة', d.scientificName.isNotEmpty ? d.scientificName : '—'),
            _infoTile('المصدر', d.source),
            const SizedBox(height: 24),
            Text(
              'كل الأشكال (نفس المادة الفعالة)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildFormsSection(),
            const SizedBox(height: 24),
            _buildAlternativesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.savings_outlined, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 6),
            Text(
              'بدائل أوفر (نفس المادة الفعالة)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingAlt)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_alternatives.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('لا توجد بدائل أرخص متاحة لهذا الدواء.'),
          )
        else
          Column(
            children: _alternatives.map((a) {
              final saving = (widget.drug.priceEgp != null &&
                      a.priceEgp != null)
                  ? widget.drug.priceEgp! - a.priceEgp!
                  : null;
              return Card(
                color: Colors.green.withValues(alpha: 0.06),
                child: ListTile(
                  leading: const Icon(Icons.arrow_downward, color: Colors.green),
                  title: Text(a.displayName),
                  subtitle: Text(
                    a.manufacturer.isNotEmpty
                        ? '${a.manufacturer} • ${a.category}'
                        : a.category,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(a.priceLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (saving != null && saving > 0)
                        Text('وفّر ${saving.toStringAsFixed(2)} ج.م',
                            style: TextStyle(
                                fontSize: 11, color: Colors.green.shade700)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFormsSection() {
    if (_loadingForms) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_forms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('لا توجد أشكال أخرى متاحة.'),
      );
    }
    return Column(
      children: _forms.map((f) {
        final isCurrent = f.id == widget.drug.id;
        return Card(
          color: isCurrent ? Colors.teal.withValues(alpha: 0.08) : null,
          child: ListTile(
            title: Text(f.displayName),
            subtitle: Text(f.tradeNameEn),
            trailing: Text(f.priceLabel),
            leading: Chip(
              label: Text(f.category),
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _title(String t) =>
      Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold));

  Widget _subtitle(String t) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(t, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      );

  Widget _infoTile(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
