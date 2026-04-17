import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restall/models/Product.dart';

class WishlistProvider with ChangeNotifier {
  static const String _wishlistKey = 'wishlist_items';

  List<Product> _items = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  List<Product> get items => [..._items];
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Constructor - inizializza automaticamente
  WishlistProvider() {
    _initializeWishlist();
  }

  /// Inizializza la wishlist caricando i dati salvati
  Future<void> _initializeWishlist() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _loadWishlistFromStorage();
      _isInitialized = true;
      print('✅ Wishlist inizializzata: ${_items.length} prodotti');
    } catch (e) {
      print('❌ Errore inizializzazione wishlist: $e');
      _items = []; // Fallback a lista vuota
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carica la wishlist da SharedPreferences
  Future<void> _loadWishlistFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistString = prefs.getString(_wishlistKey);

      if (wishlistString != null && wishlistString.isNotEmpty) {
        final List<dynamic> wishlistJson = jsonDecode(wishlistString);
        _items = wishlistJson.map((item) => Product.fromJson(item)).toList();

        // Rimuovi eventuali duplicati basati sull'ID
        _items = _removeDuplicates(_items);

        print('📱 Wishlist caricata: ${_items.length} prodotti');
      } else {
        _items = [];
        print('📱 Nessuna wishlist salvata trovata');
      }
    } catch (e) {
      print('❌ Errore caricamento wishlist: $e');
      _items = [];
    }
  }

  /// Salva la wishlist in SharedPreferences
  Future<void> _saveWishlistToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = _items.map((item) => item.toJson()).toList();
      final wishlistString = jsonEncode(wishlistJson);

      await prefs.setString(_wishlistKey, wishlistString);
      print('💾 Wishlist salvata: ${_items.length} prodotti');
    } catch (e) {
      print('❌ Errore salvataggio wishlist: $e');
    }
  }

  /// Aggiunge un prodotto alla wishlist
  Future<void> addItem(Product product) async {
    if (!_isInitialized) {
      await _initializeWishlist();
    }

    if (!isInWishlist(product.id)) {
      _items.add(product);
      await _saveWishlistToStorage();
      notifyListeners();

      print('❤️ Prodotto aggiunto alla wishlist: ${product.name}');
    }
  }

  /// Rimuove un prodotto dalla wishlist
  Future<void> removeItem(int productId) async {
    if (!_isInitialized) {
      await _initializeWishlist();
    }

    final initialLength = _items.length;
    _items.removeWhere((item) => item.id == productId);

    if (_items.length != initialLength) {
      await _saveWishlistToStorage();
      notifyListeners();

      print('💔 Prodotto rimosso dalla wishlist: ID $productId');
    }
  }

  /// Controlla se un prodotto è nella wishlist
  bool isInWishlist(int productId) {
    return _items.any((item) => item.id == productId);
  }

  /// Toggle prodotto nella wishlist
  Future<void> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      await removeItem(product.id);
    } else {
      await addItem(product);
    }
  }

  /// Rimuove tutti i prodotti dalla wishlist
  Future<void> clearWishlist() async {
    _items.clear();
    await _saveWishlistToStorage();
    notifyListeners();

    print('🗑️ Wishlist svuotata completamente');
  }

  /// Trova un prodotto per ID
  Product? getProductById(int productId) {
    try {
      return _items.firstWhere((item) => item.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Ricarica la wishlist (utile per il pull-to-refresh)
  Future<void> refreshWishlist() async {
    await _loadWishlistFromStorage();
    notifyListeners();
  }

  /// Rimuove duplicati dalla lista (safety check)
  List<Product> _removeDuplicates(List<Product> products) {
    final seen = <int>{};
    return products.where((product) => seen.add(product.id)).toList();
  }

  /// Ottieni prodotti ordinati per data aggiunta (più recenti prima)
  List<Product> get itemsSortedByNewest => [..._items.reversed];

  /// Filtra prodotti per categoria
  List<Product> getItemsByCategory(String categoryName) {
    return _items
        .where((product) => product.categories.any((cat) =>
            cat.name.toLowerCase().contains(categoryName.toLowerCase())))
        .toList();
  }

  /// Statistiche wishlist
  Map<String, int> get stats {
    final Map<String, int> categoryCount = {};

    for (final product in _items) {
      for (final category in product.categories) {
        categoryCount[category.name] = (categoryCount[category.name] ?? 0) + 1;
      }
    }

    return {
      'total': _items.length,
      'categories': categoryCount.length,
      ...categoryCount,
    };
  }
}
