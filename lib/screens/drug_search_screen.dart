import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/drug_provider.dart';
import 'drug_detail_screen.dart';
import 'favorites_screen.dart';
import 'compare_screen.dart';

/// RTL Arabic drug search screen — redesigned, with tabs (trade / ingredient),
/// favorites, compare-selection, and pagination.
class DrugSearchScreen extends StatefulWidget {
  const DrugSearchScreen({super.key});

  @override
  State<DrugSearchScreen> createState() => _DrugSearchScreenState();
}

class _DrugSearchScreenState extends State<DrugSearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DrugProvider>().init();
    });
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<DrugProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DrugProvider>();
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دليل الأدوية المصرية'),
          actions: [
            IconButton(
              icon: Badge(
                label: Text('${prov.favorites.length}'),
                isLabelVisible: prov.favorites.isNotEmpty,
                child: const Icon(Icons.favorite_border),
              ),
              tooltip: 'المفضّلة / قائمة التسوّق',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search + tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _ctrl,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: prov.searchBy == 'scientific'
                      ? 'ابحث بالمادة الفعالة (مثل PARACETAMOL)'
                      : 'ابحث باسم الدواء (عربي أو إنجليزي)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _ctrl.clear();
                            prov.search('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
                onChanged: prov.search,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'trade', label: Text('بالاسم'), icon: Icon(Icons.abc)),
                  ButtonSegment(
                      value: 'scientific',
                      label: Text('بالمادة الفعالة'),
                      icon: Icon(Icons.science_outlined)),
                ],
                selected: {prov.searchBy},
                onSelectionChanged: (s) => prov.setSearchBy(s.first),
                showSelectedIcon: false,
              ),
            ),

            _sectionLabel(theme, 'الشكل الصيدلي'),
            _buildCategoryChips(prov, theme),
            _buildFilterBar(prov, theme, context),
            _buildStatusLine(prov, theme),

            Expanded(
              child: prov.loading
                  ? const Center(child: CircularProgressIndicator())
                  : prov.results.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.medication_outlined,
                                  size: 56, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('لا توجد نتائج',
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        )
                      : _buildResults(prov),
            ),
          ],
        ),
        // Compare FAB appears when 2 drugs are selected
        floatingActionButton: prov.compareMode
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CompareScreen()),
                ),
                icon: const Icon(Icons.compare_arrows),
                label: Text('مقارنة (${prov.compareIds.length})'),
              )
            : null,
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(DrugProvider prov, ThemeData theme) {
    final cats = ['الكل', ...prov.categories];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final c = cats[i];
          final selected = prov.selectedCategory == c;
          return ChoiceChip(
            label: Text(c),
            selected: selected,
            onSelected: (_) => prov.setCategory(c),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(
      DrugProvider prov, ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _FilterChipButton(
              icon: Icons.category_outlined,
              label: prov.selectedTherapy == 'الكل'
                  ? 'المجموعة'
                  : prov.selectedTherapy,
              active: prov.selectedTherapy != 'الكل',
              onTap: () => _openTherapySheet(context, prov, theme),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterChipButton(
              icon: Icons.attach_money,
              label: prov.priceFilterOn
                  ? '${prov.minPrice?.toStringAsFixed(0) ?? '—'} ← ${prov.maxPrice?.toStringAsFixed(0) ?? '—'}'
                  : 'السعر',
              active: prov.priceFilterOn,
              onTap: () => _openPriceSheet(context, prov, theme),
            ),
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            icon: _sortIcon(prov.sortBy),
            label: _sortLabel(prov.sortBy),
            active: prov.sortBy != 'name',
            onTap: () => prov.cycleSort(),
          ),
        ],
      ),
    );
  }

  IconData _sortIcon(String s) => switch (s) {
        'price_asc' => Icons.arrow_upward_rounded,
        'price_desc' => Icons.arrow_downward_rounded,
        _ => Icons.sort_by_alpha,
      };

  String _sortLabel(String s) => switch (s) {
        'price_asc' => 'السعر ↑',
        'price_desc' => 'السعر ↓',
        _ => 'الاسم',
      };

  Widget _buildStatusLine(DrugProvider prov, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text(
              '${prov.resultCount} من ${prov.matchedCount} نتيجة',
              style: theme.textTheme.bodySmall),
          if (prov.compareMode) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: prov.clearCompare,
                child: Row(
                  children: [
                    Text('مقارنة ${prov.compareIds.length}',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSecondaryContainer)),
                    const SizedBox(width: 4),
                    const Icon(Icons.close, size: 14),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          const Text('كatalog يونيو 2026',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildResults(DrugProvider prov) {
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      itemCount: prov.results.length + (prov.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (i >= prov.results.length) {
          // Load-more indicator / button
          return prov.loadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () => prov.loadMore(),
                      icon: const Icon(Icons.expand_more),
                      label: const Text('تحميل المزيد'),
                    ),
                  ),
                );
        }
        final d = prov.results[i];
        final fav = prov.isFavorite(d);
        final comparing = prov.isComparing(d);
        return Card(
          color: comparing ? Theme.of(ctx).colorScheme.secondaryContainer : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => DrugDetailScreen(drug: d)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(ctx).style,
                            children: [
                              TextSpan(
                                text: d.displayName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (d.tradeNameEn.isNotEmpty)
                                TextSpan(
                                  text: '  ${d.tradeNameEn}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          fav ? Icons.favorite : Icons.favorite_border,
                          color: fav ? Colors.red : null,
                        ),
                        onPressed: () => prov.toggleFavorite(d),
                        tooltip: 'مفضّلة',
                      ),
                      Checkbox(
                        value: comparing,
                        onChanged: (_) => prov.toggleCompare(d),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(d.priceLabel, Colors.green, ctx),
                      _chip('الفئة: ${d.category}', Colors.blueGrey, ctx),
                      if (d.therapyClass.isNotEmpty)
                        _chip('المجموعة: ${d.therapyClass}', Colors.indigo, ctx),
                      if (d.manufacturer.isNotEmpty)
                        _chip('الشركة: ${d.manufacturer}', Colors.teal, ctx),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- Bottom sheets ----------------------------------------------------

  void _openTherapySheet(
      BuildContext context, DrugProvider prov, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('اختر المجموعة العلاجية',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: prov.therapyClasses
                      .map((t) => ListTile(
                            title: Text(t),
                            leading: Radio<String>(
                              value: t,
                              groupValue: prov.selectedTherapy,
                              onChanged: (v) {
                                prov.setTherapy(v!);
                                Navigator.pop(ctx);
                              },
                            ),
                            onTap: () {
                              prov.setTherapy(t);
                              Navigator.pop(ctx);
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPriceSheet(
      BuildContext context, DrugProvider prov, ThemeData theme) {
    final minCtl = TextEditingController(
        text: prov.minPrice?.toStringAsFixed(0) ?? '');
    final maxCtl = TextEditingController(
        text: prov.maxPrice?.toStringAsFixed(0) ?? '');
    final presets = [
      const _Preset('أقل من 20', null, 20.0),
      const _Preset('20 - 50', 20.0, 50.0),
      const _Preset('50 - 100', 50.0, 100.0),
      const _Preset('100 - 300', 100.0, 300.0),
      const _Preset('أكثر من 300', 300.0, null),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تصفية بالسعر (ج.م)',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presets
                      .map((p) => ActionChip(
                            label: Text(p.label),
                            onPressed: () {
                              prov.setPriceRange(p.min, p.max);
                              Navigator.pop(ctx);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'من',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'إلى',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          prov.clearPriceRange();
                        },
                        child: const Text('مسح'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final min = double.tryParse(minCtl.text);
                          final max = double.tryParse(maxCtl.text);
                          Navigator.pop(ctx);
                          prov.setPriceRange(min, max);
                        },
                        child: const Text('تطبيق'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Preset {
  final String label;
  final double? min;
  final double? max;
  const _Preset(this.label, this.min, this.max);
}

class _FilterChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChipButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: active
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
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

Widget _chip(String label, Color color, BuildContext ctx) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12),
    ),
  );
}
