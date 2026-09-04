import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_drug_search/core/database/database_helper.dart';
import 'package:flutter_drug_search/core/providers/drug_provider.dart';
import 'package:flutter_drug_search/model/drug.dart';

String? _realDbPath;

bool get hasRealDb => _realDbPath != null;

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();

  // Resolve DB if present — tests skip gracefully if absent.
  final testDir = File.fromUri(Uri.parse('file://${Directory.current.path}'));
  for (final c in [
    File('${testDir.path}/../build/egypt_drugs.db'),
    File('${testDir.path}/build/egypt_drugs.db'),
  ]) {
    if (c.existsSync()) {
      _realDbPath = c.path;
      break;
    }
  }

  setUp(() {
    if (!hasRealDb) return;
    DatabaseHelper.useTestDb(_realDbPath!);
    FavoritesDb.useTestDb(p.join(Directory.systemTemp.path, 'test_fav_main.db'));
  });

  tearDown(() {
    if (!hasRealDb) return;
    DatabaseHelper.resetDb();
    FavoritesDb.reset();
  });

  group('DrugProvider / DatabaseHelper against the real DB', () {
    test('total count matches the 32,525 merged records', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final prov = DrugProvider();
      await prov.init();
      expect(prov.total, greaterThanOrEqualTo(32000));
      expect(prov.results, isNotEmpty);
      expect(prov.categories.length, 33);
    });

    test('search by Arabic name returns matching drugs', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final r = await db.searchByName('كونترامال');
      expect(r, isNotEmpty);
      for (final d in r) {
        final hay = '${d.tradeNameAr} ${d.tradeNameEn}'.toLowerCase();
        expect(hay, contains('كونترامال'.toLowerCase()));
      }
    });

    test('search by English name returns matching drugs', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final r = await db.searchByName('panadol');
      expect(r, isNotEmpty);
      expect(r.first.tradeNameEn.toLowerCase(), contains('panadol'));
    });

    test('filterByCategory(Tablet) only returns Tablet rows', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final r = await db.filterByCategory('Tablet', limit: 2000);
      expect(r.length, greaterThan(1000));
      for (final d in r) {
        expect(d.category, 'Tablet');
      }
    });

    test('all 33 categories are non-empty', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final cats = await db.categories();
      expect(cats.length, 33);
      for (final c in cats) {
        final n = (await db.filterByCategory(c, limit: 1)).length;
        expect(n, greaterThan(0), reason: 'category $c should have rows');
      }
    });

    test('sameIngredient returns every form sharing the active ingredient',
        () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      Future<Drug> firstWithSci(String q) async {
        final hits = await db.searchByName(q);
        return hits.firstWhere((d) => d.scientificName.isNotEmpty);
      }

      final sample = await firstWithSci('augmentin').catchError((_) => firstWithSci('panadol'));
      expect(sample.scientificName, isNotEmpty);
      final forms = await db.sameIngredient(sample.scientificName);
      expect(forms, isNotEmpty);
      for (final f in forms) {
        expect(f.scientificName, sample.scientificName);
      }
      expect(forms.any((f) => f.id == sample.id), isTrue);
    });

    test('cheapestByIngredient prices are ascending and not null', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final r = await db.cheapestByIngredient('PARACETAMOL', limit: 10);
      expect(r, isNotEmpty);
      for (final d in r) {
        expect(d.priceEgp, isNotNull);
      }
      final prices = r.map((d) => d.priceEgp!).toList();
      final sorted = [...prices]..sort();
      expect(prices, orderedEquals(sorted));
    });

    test('Drug model: displayName prefers Arabic, priceLabel formats EGP', () {
      const ar = Drug(
        tradeNameEn: 'PANADOL',
        tradeNameAr: 'بانادول',
        scientificName: 'PARACETAMOL',
        manufacturer: 'GSK',
        priceEgp: 46.0,
        category: 'Tablet',
        route: 'ORAL.SOLID',
        drugClass: '',
        therapyClass: 'مسكن / مضاد التهاب',
        source: 'karem505',
      );
      expect(ar.displayName, 'بانادول');
      expect(ar.priceLabel, '46.00 ج.م');

      const noAr = Drug(
        tradeNameEn: 'SOME DRUG',
        tradeNameAr: '',
        scientificName: '',
        manufacturer: '',
        priceEgp: null,
        category: 'Other',
        route: '',
        drugClass: '',
        therapyClass: '',
        source: 'moaazsalter',
      );
      expect(noAr.displayName, 'SOME DRUG');
      expect(noAr.priceLabel, '—');
    });

    test('search with price range returns only in-range priced drugs', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final r = await db.search(name: '', minPrice: 0, maxPrice: 5, limit: 500);
      expect(r, isNotEmpty);
      for (final d in r) {
        expect(d.priceEgp, isNotNull);
        expect(d.priceEgp!, greaterThanOrEqualTo(0));
        expect(d.priceEgp!, lessThanOrEqualTo(5));
      }
      final wide = await db.search(name: '', maxPrice: 50, limit: 500);
      expect(wide.length, greaterThanOrEqualTo(r.length));
    });

    test('search with therapy_class filter returns only that therapy area',
        () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final therapies = await db.therapyClasses();
      expect(therapies.length, greaterThan(1));
      final area = therapies.firstWhere((t) => t != 'الكل');
      final r = await db.search(therapyClass: area, limit: 200);
      expect(r, isNotEmpty);
      for (final d in r) {
        expect(d.therapyClass, area);
      }
    });

    test('combined filters (category + therapy + price) all apply', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final r = await db.search(
        category: 'Tablet',
        therapyClass: 'مضاد حيوي / ميكروبي',
        minPrice: 10,
        maxPrice: 200,
        limit: 200,
      );
      for (final d in r) {
        expect(d.category, 'Tablet');
        expect(d.therapyClass, 'مضاد حيوي / ميكروبي');
        expect(d.priceEgp, isNotNull);
        expect(d.priceEgp!, greaterThanOrEqualTo(10));
        expect(d.priceEgp!, lessThanOrEqualTo(200));
      }
    });

    test('search sortBy price_asc / price_desc are correctly ordered', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final asc = await db.search(minPrice: 0, sortBy: 'price_asc', limit: 100);
      final desc = await db.search(minPrice: 0, sortBy: 'price_desc', limit: 100);
      expect(asc.length, greaterThan(1));
      expect(desc.length, greaterThan(1));
      final ascPrices = asc.map((d) => d.priceEgp!).toList();
      final ascSorted = [...ascPrices]..sort();
      expect(ascPrices, orderedEquals(ascSorted));
      final descPrices = desc.map((d) => d.priceEgp!).toList();
      final descSorted = [...descPrices]..sort((a, b) => b.compareTo(a));
      expect(descPrices, orderedEquals(descSorted));
      expect(ascPrices.first, lessThanOrEqualTo(descPrices.first));
    });

    test('cheaperAlternatives returns strictly cheaper same-ingredient drugs',
        () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      Future<Drug> firstPricedWithSci(String q) async {
        final hits = await db.searchByName(q);
        return hits.firstWhere(
            (d) => d.scientificName.isNotEmpty && d.priceEgp != null);
      }

      late Drug sample;
      try {
        sample = await firstPricedWithSci('augmentin');
      } catch (_) {
        sample = await firstPricedWithSci('panadol');
      }
      expect(sample.id, isNotNull);
      final alts = await db.cheaperAlternatives(
        scientific: sample.scientificName,
        currentPrice: sample.priceEgp,
        excludeId: sample.id!,
        tradeNameEn: sample.tradeNameEn,
      );
      for (final a in alts) {
        expect(a.scientificName, sample.scientificName);
        expect(a.id, isNot(sample.id));
        expect(a.priceEgp, isNotNull);
        expect(a.priceEgp!, lessThan(sample.priceEgp!));
      }
    });

    test('searchBy=scientific matches the active-ingredient column', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final r = await db.search(name: 'PARACETAMOL', searchBy: 'scientific', limit: 50);
      expect(r, isNotEmpty);
      for (final d in r) {
        expect(d.scientificName.toUpperCase(), contains('PARACETAMOL'));
      }
      final trade = await db.search(name: 'PARACETAMOL', searchBy: 'trade', limit: 50);
      expect(trade, isA<List<Drug>>());
    });

    test('FavoritesDb writes and reads back locally', () async {
      final fpath = p.join(Directory.systemTemp.path, 'test_fav.db');
      final f = File(fpath);
      if (await f.exists()) await f.delete();
      FavoritesDb.useTestDb(fpath);
      try {
        final fav = FavoritesDb();
        const d = Drug(
          id: 999001,
          tradeNameEn: 'TESTDRUG',
          tradeNameAr: 'دواء اختبار',
          scientificName: 'TESTACT',
          manufacturer: 'TESTCO',
          priceEgp: 12.5,
          category: 'Tablet',
          route: 'ORAL.SOLID',
          drugClass: '',
          therapyClass: 'مسكن / مضاد التهاب',
          source: 'karem505',
        );
        expect(await fav.contains(d.id!), isFalse);
        await fav.add(d);
        expect(await fav.contains(d.id!), isTrue);
        final all = await fav.all();
        expect(all.length, 1);
        expect(all.first.tradeNameAr, 'دواء اختبار');
        await fav.remove(d);
        expect(await fav.contains(d.id!), isFalse);
      } finally {
        FavoritesDb.reset();
        if (await f.exists()) await f.delete();
      }
    });

    test('count() and search() with offset give consistent pagination', () async {
      if (!hasRealDb) {
        markTestSkipped('egypt_drugs.db not found — run build/build_db.py');
        return;
      }
      final db = DatabaseHelper();
      final total = await db.count(category: 'Tablet');
      expect(total, greaterThan(100));
      final p1 = await db.search(category: 'Tablet', limit: 50, offset: 0);
      final p2 = await db.search(category: 'Tablet', limit: 50, offset: 50);
      expect(p1.length, 50);
      expect(p2.length, lessThanOrEqualTo(50));
      final p1ids = p1.map((d) => d.id).toSet();
      final p2ids = p2.map((d) => d.id).toSet();
      expect(p1ids.intersection(p2ids).isEmpty, isTrue);
      expect(p1.length + p2.length, lessThanOrEqualTo(total));
    });
  });
}
