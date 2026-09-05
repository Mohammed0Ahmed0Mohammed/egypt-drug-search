import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../model/drug.dart';

/// Singleton DB helper for the merged Egyptian drug database.
///
/// The database ships as a prebuilt asset (`assets/egypt_drugs.db`, built by
/// build_db.py) and is copied once to the app documents dir. Uses
/// `sqflite_common_ffi` so it runs on desktop (Linux/Windows/macOS) exactly
/// like the Power Gym app.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _dbAsset = 'assets/egypt_drugs.db';
  static const String _dbFileName = 'egypt_drugs.db';
  static Database? _database;

  /// Test seam: when set, queries run against this file instead of the
  /// bundled asset (mirrors Power Gym's createForTesting pattern). Lets a
  /// flutter test exercise the REAL query methods against the real DB.
  static String? _testDbPath;
  static void useTestDb(String path) {
    _testDbPath = path;
    _database = null;
  }

  static Future<void> resetDb() async {
    _testDbPath = null;
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = _testDbPath ?? await _ensureDbFile();
    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        // read-only: the DB is prebuilt; we never write at runtime.
        readOnly: true,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  /// Copies the bundled DB into the documents dir on first run.
  Future<String> _ensureDbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(dir.path, 'EgyptDrugDB'));
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    final dbPath = p.join(dbDir.path, _dbFileName);

    if (!await File(dbPath).exists()) {
      final bytes = await rootBundle.load(_dbAsset);
      await File(dbPath).writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    }
    return dbPath;
  }

  // ----------------------------------------------------------------------
  // Queries
  // ----------------------------------------------------------------------

  /// Search by Arabic or English trade name (case-insensitive LIKE).
  Future<List<Drug>> searchByName(String query, {int limit = 100}) async {
    final db = await database;
    final q = query.trim();
    if (q.isEmpty) return const [];
    final like = '%$q%';
    final rows = await db.query(
      'drugs',
      where: 'trade_name_ar LIKE ? OR trade_name_en LIKE ?',
      whereArgs: [like, like],
      limit: limit,
    );
    return rows.map(Drug.fromMap).toList();
  }

  /// Filter by one of the 33 standardized categories.
  Future<List<Drug>> filterByCategory(String category, {int limit = 200}) async {
    final db = await database;
    final rows = await db.query(
      'drugs',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'trade_name_ar ASC',
      limit: limit,
    );
    return rows.map(Drug.fromMap).toList();
  }

  /// Combined search + category + therapy-area + price-range filter.
  /// [sortBy] is either 'name' (default, RTL alpha) or 'price_asc'/'price_desc'.
  /// [searchBy] switches the name query to match 'trade' (default) or
  /// 'scientific' (active ingredient) columns.
  /// [offset] enables pagination (0-based).
  Future<List<Drug>> search({
    String name = '',
    String? category,
    String? therapyClass,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'name',
    String searchBy = 'trade',
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final clauses = <String>[];
    final args = <Object>[];
    if (name.trim().isNotEmpty) {
      if (searchBy == 'scientific') {
        clauses.add('scientific_name LIKE ?');
        args.add('%$name%');
      } else {
        clauses.add('(trade_name_ar LIKE ? OR trade_name_en LIKE ?)');
        args.add('%$name%');
        args.add('%$name%');
      }
    }
    if (category != null && category != 'الكل') {
      clauses.add('category = ?');
      args.add(category);
    }
    if (therapyClass != null && therapyClass != 'الكل') {
      clauses.add('therapy_class = ?');
      args.add(therapyClass);
    }
    if (minPrice != null) {
      clauses.add('price_egp >= ?');
      args.add(minPrice);
    }
    if (maxPrice != null) {
      clauses.add('price_egp <= ?');
      args.add(maxPrice);
    }
    final orderBy = switch (sortBy) {
      'price_asc' => 'CASE WHEN price_egp IS NULL THEN 1 ELSE 0 END, price_egp ASC',
      'price_desc' => 'CASE WHEN price_egp IS NULL THEN 1 ELSE 0 END, price_egp DESC',
      _ => 'trade_name_ar ASC',
    };
    final rows = await db.query(
      'drugs',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return rows.map(Drug.fromMap).toList();
  }

  /// Total count matching the current filters (for pagination).
  Future<int> count({
    String name = '',
    String? category,
    String? therapyClass,
    double? minPrice,
    double? maxPrice,
    String searchBy = 'trade',
  }) async {
    final db = await database;
    final clauses = <String>[];
    final args = <Object>[];
    if (name.trim().isNotEmpty) {
      if (searchBy == 'scientific') {
        clauses.add('scientific_name LIKE ?');
        args.add('%$name%');
      } else {
        clauses.add('(trade_name_ar LIKE ? OR trade_name_en LIKE ?)');
        args.add('%$name%');
        args.add('%$name%');
      }
    }
    if (category != null && category != 'الكل') {
      clauses.add('category = ?');
      args.add(category);
    }
    if (therapyClass != null && therapyClass != 'الكل') {
      clauses.add('therapy_class = ?');
      args.add(therapyClass);
    }
    if (minPrice != null) {
      clauses.add('price_egp >= ?');
      args.add(minPrice);
    }
    if (maxPrice != null) {
      clauses.add('price_egp <= ?');
      args.add(maxPrice);
    }
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM drugs ${clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}'}',
      args,
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// The 33 standardized categories from MoaazSalter's EDA taxonomy.
  Future<List<String>> categories() async {
    final db = await database;
    final rows =
        await db.query('categories', columns: ['name'], orderBy: 'id ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  /// The normalized therapy areas derived from drug_class (for the 2nd filter row).
  Future<List<String>> therapyClasses() async {
    final db = await database;
    final rows = await db.query('therapy_classes',
        columns: ['name'], where: "name <> ?", whereArgs: ['أخرى'], orderBy: 'id ASC');
    final names = rows.map((r) => r['name'] as String).toList();
    return ['الكل', ...names];
  }

  /// Cheapest N drugs containing a scientific ingredient (for price comparison).
  Future<List<Drug>> cheapestByIngredient(String ingredient, {int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      'drugs',
      where: "scientific_name LIKE ? AND price_egp IS NOT NULL",
      whereArgs: ['%$ingredient%'],
      orderBy: 'price_egp ASC',
      limit: limit,
    );
    return rows.map(Drug.fromMap).toList();
  }

  /// All dosage forms sharing the same active ingredient as [scientific].
  /// Used by the detail screen's "كل الأشكال" (all forms) section.
  /// Returns ALL matching forms (high limit) sorted cheapest-first.
  Future<List<Drug>> sameIngredient(String scientific, {int limit = 500}) async {
    final db = await database;
    final rows = await db.query(
      'drugs',
      where: 'scientific_name = ?',
      whereArgs: [scientific],
      orderBy: 'price_egp ASC',
      limit: limit,
    );
    return rows.map(Drug.fromMap).toList();
  }

  /// Fallback for rows with no scientific name: every drug whose trade name
  /// starts with [base] (case-insensitive), e.g. "Augmentin".
  Future<List<Drug>> sameBaseName(String base, {int limit = 500}) async {
    final db = await database;
    final rows = await db.query(
      'drugs',
      where: 'trade_name_en LIKE ? OR trade_name_ar LIKE ?',
      whereArgs: ['$base%', '$base%'],
      orderBy: 'price_egp ASC',
      limit: limit,
    );
    return rows.map(Drug.fromMap).toList();
  }

  /// Cheaper alternatives: same active ingredient, different manufacturer,
  /// priced strictly lower than [currentPrice]. Sorted cheapest-first.
  /// Returns up to [limit] suggestions for cost-saving. [excludeId] skips the
  /// drug the user is currently viewing. Falls back to base-name match when
  /// [scientific] is empty (MoaazSalter rows have no scientific name).
  Future<List<Drug>> cheaperAlternatives({
    required String scientific,
    required double? currentPrice,
    required int excludeId,
    String tradeNameEn = '',
    int limit = 10,
  }) async {
    final db = await database;
    List<Map<String, Object?>> rows;
    if (scientific.isNotEmpty) {
      final args = <Object>[scientific];
      var where = 'scientific_name = ? AND id <> ?';
      args.add(excludeId);
      if (currentPrice != null) {
        where += ' AND price_egp IS NOT NULL AND price_egp < ?';
        args.add(currentPrice);
      }
      rows = await db.query(
        'drugs',
        where: where,
        whereArgs: args,
        orderBy: 'price_egp ASC',
        limit: limit,
      );
    } else if (tradeNameEn.isNotEmpty) {
      final base = tradeNameEn.split(RegExp(r'[\s.]+')).first;
      var where = 'trade_name_en LIKE ? AND id <> ?';
      final args = <Object>['$base%', excludeId];
      if (currentPrice != null) {
        where += ' AND price_egp IS NOT NULL AND price_egp < ?';
        args.add(currentPrice);
      }
      rows = await db.query(
        'drugs',
        where: where,
        whereArgs: args,
        orderBy: 'price_egp ASC',
        limit: limit,
      );
    } else {
      return const [];
    }
    return rows.map(Drug.fromMap).toList();
  }

  Future<int> totalCount() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM drugs');
    return (r.first['c'] as int?) ?? 0;
  }
}

/// Local, writable favorites / shopping-list store (sqflite_ffi).
///
/// Separate from the read-only bundled catalog. Exists only on the user's
/// device; we never touch the shipped asset. Matches Power Gym's writable-DB
/// pattern (open with readOnly: false).
class FavoritesDb {
  static final FavoritesDb _instance = FavoritesDb._internal();
  factory FavoritesDb() => _instance;
  FavoritesDb._internal();

  static Database? _db;
  static bool _testMode = false;
  static String? _testPath;

  static void useTestDb(String path) {
    _testPath = path;
    _testMode = true;
    _db = null;
  }

  static Future<void> reset() async {
    _testPath = null;
    _testMode = false;
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final path = _testMode
        ? _testPath!
        : await _defaultPath();
    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE favorites (
              id INTEGER PRIMARY KEY,
              trade_name_en TEXT,
              trade_name_ar TEXT,
              scientific_name TEXT,
              manufacturer TEXT,
              price_egp REAL,
              category TEXT,
              route TEXT,
              therapy_class TEXT,
              added_at TEXT
            )
          ''');
        },
      ),
    );
    return _db!;
  }

  Future<String> _defaultPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final fdir = Directory(p.join(dir.path, 'EgyptDrugDB'));
    if (!await fdir.exists()) await fdir.create(recursive: true);
    return p.join(fdir.path, 'favorites.db');
  }

  Future<void> add(Drug d) async {
    final db = await database;
    await db.insert(
      'favorites',
      {
        'id': d.id,
        'trade_name_en': d.tradeNameEn,
        'trade_name_ar': d.tradeNameAr,
        'scientific_name': d.scientificName,
        'manufacturer': d.manufacturer,
        'price_egp': d.priceEgp,
        'category': d.category,
        'route': d.route,
        'therapy_class': d.therapyClass,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(Drug d) async {
    if (d.id == null) return;
    final db = await database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [d.id]);
  }

  Future<bool> contains(int id) async {
    final db = await database;
    final r = await db.query('favorites', where: 'id = ?', whereArgs: [id]);
    return r.isNotEmpty;
  }

  Future<List<Drug>> all() async {
    final db = await database;
    final rows = await db.query('favorites', orderBy: 'added_at DESC');
    return rows
        .map((m) => Drug.fromMap({...m, 'source': 'favorite'}))
        .toList();
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete('favorites');
  }
}
