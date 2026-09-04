/// Data model for a single drug record in the merged Egyptian drug database.
///
/// Source: combined `karem505` (Arabic name + EGP price + scientific name +
/// manufacturer) and `moaazsalter` (33 standardized dosage-form categories
/// scraped from the official EDA portal). See build_db.py for the merge logic.
class Drug {
  final int? id;
  final String tradeNameEn;
  final String tradeNameAr;
  final String scientificName;
  final String manufacturer;
  final double? priceEgp;
  final String category;
  final String route;
  final String drugClass;
  final String therapyClass;
  final String source;

  const Drug({
    this.id,
    required this.tradeNameEn,
    required this.tradeNameAr,
    required this.scientificName,
    required this.manufacturer,
    this.priceEgp,
    required this.category,
    required this.route,
    required this.drugClass,
    required this.therapyClass,
    required this.source,
  });

  factory Drug.fromMap(Map<String, dynamic> m) => Drug(
        id: m['id'] as int?,
        tradeNameEn: (m['trade_name_en'] as String?) ?? '',
        tradeNameAr: (m['trade_name_ar'] as String?) ?? '',
        scientificName: (m['scientific_name'] as String?) ?? '',
        manufacturer: (m['manufacturer'] as String?) ?? '',
        priceEgp: m['price_egp'] == null ? null : (m['price_egp'] as num).toDouble(),
        category: (m['category'] as String?) ?? 'Other',
        route: (m['route'] as String?) ?? '',
        drugClass: (m['drug_class'] as String?) ?? '',
        therapyClass: (m['therapy_class'] as String?) ?? '',
        source: (m['source'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'trade_name_en': tradeNameEn,
        'trade_name_ar': tradeNameAr,
        'scientific_name': scientificName,
        'manufacturer': manufacturer,
        'price_egp': priceEgp,
        'category': category,
        'route': route,
        'drug_class': drugClass,
        'therapy_class': therapyClass,
        'source': source,
      };

  /// Display name: Arabic if present, otherwise English — RTL-friendly.
  String get displayName => tradeNameAr.isNotEmpty ? tradeNameAr : tradeNameEn;

  String get priceLabel =>
      priceEgp != null ? '${priceEgp!.toStringAsFixed(2)} ج.م' : '—';
}
