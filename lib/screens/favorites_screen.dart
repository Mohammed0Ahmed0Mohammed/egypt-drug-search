import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/database_helper.dart';
import '../core/providers/drug_provider.dart';
import 'drug_detail_screen.dart';

/// Favorites / shopping-list screen — drugs the user saved locally.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DrugProvider>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المفضّلة / قائمة التسوّق'),
          actions: [
            if (prov.favorites.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'مسح الكل',
                onPressed: () async {
                  await FavoritesDb().clear();
                  prov.init();
                },
              ),
          ],
        ),
        body: prov.favorites.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 56, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('لا توجد أدوية محفوظة بعد',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 6),
                    Text('اضغط القلب على أي دواء لحفظه هنا',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: prov.favorites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final d = prov.favorites[i];
                  return Card(
                    child: ListTile(
                      onTap: () => Navigator.of(ctx).push(
                        MaterialPageRoute(
                            builder: (_) => DrugDetailScreen(drug: d)),
                      ),
                      leading: const Icon(Icons.favorite, color: Colors.red),
                      title: Text(d.displayName),
                      subtitle: Text(
                          '${d.priceLabel} • ${d.manufacturer.isNotEmpty ? d.manufacturer : d.category}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => prov.toggleFavorite(d),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
