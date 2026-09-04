import 'package:flutter/material.dart';

import '../../core/database/database_helper.dart';
import '../../model/drug.dart';

/// Holds search state + results, favorites, and compare-selection for the app.
class DrugProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final FavoritesDb _fav = FavoritesDb();

  List<Drug> _results = [];
  List<Drug> _favorites = [];
  List<String> _categories = [];
  List<String> _therapyClasses = [];
  String _selectedCategory = 'الكل';
  String _selectedTherapy = 'الكل';
  double? _minPrice;
  double? _maxPrice;
  bool _priceFilterOn = false;
  String _sortBy = 'name';
  bool _loading = false;
  bool _loadingMore = false;
  String _query = '';
  String _searchBy = 'trade'; // 'trade' | 'scientific'
  final Set<int> _compareIds = {};
  int _total = 0;
  int _matchedCount = 0;

  List<Drug> get results => _results;
  List<Drug> get favorites => _favorites;
  List<String> get categories => _categories;
  List<String> get therapyClasses => _therapyClasses;
  String get selectedCategory => _selectedCategory;
  String get selectedTherapy => _selectedTherapy;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool get priceFilterOn => _priceFilterOn;
  String get sortBy => _sortBy;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String get query => _query;
  String get searchBy => _searchBy;
  int get total => _total; // full DB count
  int get resultCount => _results.length; // currently shown
  int get matchedCount => _matchedCount; // total matching current filters
  bool get hasMore => _results.length < _matchedCount;
  List<int> get compareIds => _compareIds.toList();
  bool get compareMode => _compareIds.isNotEmpty;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    _categories = await _db.categories();
    _therapyClasses = await _db.therapyClasses();
    _favorites = await _fav.all();
    _total = await _db.totalCount();
    await _runSearch(reset: true);
    _loading = false;
    notifyListeners();
  }

  Future<void> setCategory(String category) async {
    _selectedCategory = category;
    notifyListeners();
    await _runSearch(reset: true);
  }

  Future<void> setTherapy(String therapy) async {
    _selectedTherapy = therapy;
    notifyListeners();
    await _runSearch(reset: true);
  }

  void setSearchBy(String mode) {
    _searchBy = mode;
    notifyListeners();
    _runSearch(reset: true);
  }

  Future<void> setPriceRange(double? min, double? max) async {
    _minPrice = min;
    _maxPrice = max;
    _priceFilterOn = min != null || max != null;
    notifyListeners();
    await _runSearch(reset: true);
  }

  void clearPriceRange() {
    _minPrice = null;
    _maxPrice = null;
    _priceFilterOn = false;
    notifyListeners();
    _runSearch(reset: true);
  }

  void search(String query) {
    _query = query;
    _runSearch(reset: true);
  }

  /// Cycle sort order: name -> price_asc -> price_desc -> name.
  Future<void> cycleSort() async {
    _sortBy = switch (_sortBy) {
      'name' => 'price_asc',
      'price_asc' => 'price_desc',
      _ => 'name',
    };
    notifyListeners();
    await _runSearch(reset: true);
  }

  /// Load next page of results (pagination).
  Future<void> loadMore() async {
    if (_loadingMore || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    final next = await _db.search(
      name: _query,
      category: _selectedCategory == 'الكل' ? null : _selectedCategory,
      therapyClass: _selectedTherapy == 'الكل' ? null : _selectedTherapy,
      minPrice: _priceFilterOn ? _minPrice : null,
      maxPrice: _priceFilterOn ? _maxPrice : null,
      sortBy: _sortBy,
      searchBy: _searchBy,
      limit: 50,
      offset: _results.length,
    );
    _results.addAll(next);
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> _runSearch({bool reset = false}) async {
    if (reset) {
      _loading = true;
      notifyListeners();
    }
    // Get total matching count for pagination
    _matchedCount = await _db.count(
      name: _query,
      category: _selectedCategory == 'الكل' ? null : _selectedCategory,
      therapyClass: _selectedTherapy == 'الكل' ? null : _selectedTherapy,
      minPrice: _priceFilterOn ? _minPrice : null,
      maxPrice: _priceFilterOn ? _maxPrice : null,
      searchBy: _searchBy,
    );
    _results = await _db.search(
      name: _query,
      category: _selectedCategory == 'الكل' ? null : _selectedCategory,
      therapyClass: _selectedTherapy == 'الكل' ? null : _selectedTherapy,
      minPrice: _priceFilterOn ? _minPrice : null,
      maxPrice: _priceFilterOn ? _maxPrice : null,
      sortBy: _sortBy,
      searchBy: _searchBy,
      limit: 50,
      offset: 0,
    );
    _loading = false;
    notifyListeners();
  }

  // ---- Favorites / shopping list ---------------------------------------

  bool isFavorite(Drug d) => _favorites.any((f) => f.id == d.id);

  Future<void> toggleFavorite(Drug d) async {
    if (d.id == null) return;
    if (isFavorite(d)) {
      await _fav.remove(d);
    } else {
      await _fav.add(d);
    }
    _favorites = await _fav.all();
    notifyListeners();
  }

  // ---- Compare selection -------------------------------------------------

  bool isComparing(Drug d) => d.id != null && _compareIds.contains(d.id);

  void toggleCompare(Drug d) {
    if (d.id == null) return;
    if (_compareIds.contains(d.id)) {
      _compareIds.remove(d.id);
    } else {
      if (_compareIds.length >= 2) {
        _compareIds.remove(_compareIds.first); // keep max 2
      }
      _compareIds.add(d.id!);
    }
    notifyListeners();
  }

  List<Drug> getCompareDrugs() {
    // check favorites in case a compared drug scrolled out of results
    return _compareIds
        .map((id) => _results.firstWhere((d) => d.id == id,
            orElse: () => _favorites.firstWhere((d) => d.id == id,
                orElse: () => const Drug(
                    tradeNameEn: '', tradeNameAr: '', scientificName: '',
                    manufacturer: '', category: '', route: '', drugClass: '',
                    therapyClass: '', source: ''))))
        .toList();
  }

  void clearCompare() {
    _compareIds.clear();
    notifyListeners();
  }

  Future<List<Drug>> allFormsOf(String scientific,
      {String tradeNameEn = ''}) async {
    if (scientific.isNotEmpty) {
      final bySci = await _db.sameIngredient(scientific);
      if (bySci.isNotEmpty) return bySci;
    }
    if (tradeNameEn.isNotEmpty) {
      final base = tradeNameEn.split(RegExp(r'[\s.]+')).first;
      if (base.isNotEmpty) return _db.sameBaseName(base);
    }
    return const [];
  }

  Future<List<Drug>> cheaperAlternativesFor(Drug drug) async {
    if (drug.id == null) return const [];
    return _db.cheaperAlternatives(
      scientific: drug.scientificName,
      currentPrice: drug.priceEgp,
      excludeId: drug.id!,
      tradeNameEn: drug.tradeNameEn,
      limit: 10,
    );
  }
}
