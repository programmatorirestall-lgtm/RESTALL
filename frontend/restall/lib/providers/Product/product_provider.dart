import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:restall/API/Shop/product.dart';
import 'package:restall/core/performance/cache_manager.dart';
import 'package:restall/core/performance/connection_manager.dart';
import 'package:restall/models/Product.dart';

class ProductProvider with ChangeNotifier {
  final ProductApi _productApi;
  final CacheManager _cacheManager;
  final ConnectionManager _connectionManager;

  ProductProvider({
    required CacheManager cacheManager,
    required ConnectionManager connectionManager,
    ProductApi? productApi,
  })  : _cacheManager = cacheManager,
        _connectionManager = connectionManager,
        _productApi = productApi ?? ProductApi() {
    // Auto-inizializzazione come ProfileProvider
    fetchProducts();
  }

  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  final int _productsPerPage = 20;

  String _searchQuery = '';
  String _selectedCategory = '';

  // guard per evitare notify dopo dispose
  bool _isDisposed = false;

  // Getters
  List<Product> get products => [..._filteredProducts];
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreProducts => _hasMoreProducts;

  // metodo sicuro per notificare solo se non dispose-ato
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (_) {
        // sicurezza aggiuntiva: swallow se qualcosa va storto
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // --- METODI DI FETCH OTTIMIZZATI ---

  Future<void> fetchProducts({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    if (refresh) {
      _products = [];
      _filteredProducts = [];
      _currentPage = 1;
      _hasMoreProducts = true;
      _cacheManager.invalidate('products_page_1');
    }
    _safeNotifyListeners();

    final cacheKey = 'products_page_1';
    try {
      List<Product>? cachedProducts =
          _cacheManager.get<List<Product>>(cacheKey);

      if (cachedProducts != null) {
        print('✅ Prodotti caricati dalla cache: ${cachedProducts.length}');
        _products = cachedProducts;
      } else {
        print('🔄 Fetching prodotti dal server...');
        final response = await _connectionManager.executeWithRetry(
          () => _productApi.getProducts(page: 1, limit: _productsPerPage),
        );

        print('📡 Response status: ${response?.statusCode}');
        if (response != null && response.statusCode == 200) {
          print(
              '📏 Lunghezza response body: ${response.body.length} caratteri');

          // Stampa il JSON completo in chunks per evitare troncamenti
          print('📄 ===== INIZIO JSON COMPLETO =====');
          _printLongString(response.body);
          print('📄 ===== FINE JSON COMPLETO =====');

          final List<dynamic> productData = json.decode(response.body);
          print('📦 Prodotti ricevuti dal server: ${productData.length}');

          // Log dettagliato dei primi prodotti
          if (productData.isNotEmpty) {
            print('📋 Primi prodotti ricevuti:');
            for (int i = 0;
                i < (productData.length > 5 ? 5 : productData.length);
                i++) {
              final prod = productData[i];
              print('   ${i + 1}. ID: ${prod['id']}, Nome: ${prod['name']}');
            }
          }

          _products =
              productData.map((json) => Product.fromJson(json)).toList();
          print('✅ Prodotti parsati: ${_products.length}');

          // Log dei nomi dei prodotti parsati
          if (_products.isNotEmpty) {
            print('📝 Lista prodotti parsati:');
            for (int i = 0;
                i < (_products.length > 5 ? 5 : _products.length);
                i++) {
              print('   ${i + 1}. ${_products[i].name}');
            }
            if (_products.length > 5) {
              print('   ... e altri ${_products.length - 5} prodotti');
            }
          }

          _cacheManager.set(cacheKey, _products,
              ttl: const Duration(minutes: 5));
        } else {
          print('❌ Response null o status code != 200');
          if (response != null) {
            print('❌ Status code: ${response.statusCode}');
            print(
                '❌ Response body (primi 200 caratteri): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
          }
        }
      }
      _applyFilters();
      print('🎯 Prodotti dopo filtri: ${_filteredProducts.length}');
    } catch (error) {
      print('❌ Error fetching products: $error');
      print('❌ Error type: ${error.runtimeType}');
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  Future<void> fetchMoreProducts() async {
    if (_isLoading || _isLoadingMore || !_hasMoreProducts) {
      print(
          '⏸️ fetchMoreProducts bloccato: isLoading=$_isLoading, isLoadingMore=$_isLoadingMore, hasMoreProducts=$_hasMoreProducts');
      return;
    }

    print('📥 Caricamento pagina $_currentPage + 1...');
    _isLoadingMore = true;
    _safeNotifyListeners();

    _currentPage++;
    final cacheKey = 'products_page_$_currentPage';
    print('🔑 Cache key: $cacheKey');

    try {
      List<Product>? cachedProducts =
          _cacheManager.get<List<Product>>(cacheKey);
      List<Product> newProducts = [];

      if (cachedProducts != null) {
        newProducts = cachedProducts;
      } else {
        final response = await _connectionManager.executeWithRetry(
          () => _productApi.getProducts(
              page: _currentPage, limit: _productsPerPage),
        );

        if (response != null && response.statusCode == 200) {
          final List<dynamic> productData = json.decode(response.body);
          newProducts =
              productData.map((json) => Product.fromJson(json)).toList();
          _cacheManager.set(cacheKey, newProducts,
              ttl: const Duration(minutes: 5));
        }
      }

      if (newProducts.isEmpty) {
        print(
            '🏁 Nessun prodotto nella pagina $_currentPage - Fine dei prodotti');
        _hasMoreProducts = false;
      } else {
        // Filtra i prodotti duplicati (già presenti nella lista)
        final existingIds = _products.map((p) => p.id).toSet();
        final uniqueNewProducts = newProducts.where((p) => !existingIds.contains(p.id)).toList();

        if (uniqueNewProducts.isEmpty) {
          print(
              '🔄 Tutti i ${newProducts.length} prodotti dalla pagina $_currentPage sono duplicati - Fine dei prodotti');
          _hasMoreProducts = false;
        } else {
          print(
              '✅ Aggiunti ${uniqueNewProducts.length} prodotti nuovi dalla pagina $_currentPage (${newProducts.length - uniqueNewProducts.length} duplicati filtrati)');
          _products.addAll(uniqueNewProducts);
          print('📊 Totale prodotti ora: ${_products.length}');
          _applyFilters();

          // Se abbiamo ricevuto meno prodotti unici del limite, probabilmente non ce ne sono altri
          if (uniqueNewProducts.length < _productsPerPage) {
            print('⚠️ Ricevuti meno prodotti del limite ($_productsPerPage) - Probabilmente fine dei prodotti');
            _hasMoreProducts = false;
          }
        }
      }
    } catch (error) {
      print('Error fetching more products: $error');
      _currentPage--; // Rollback page number on error
    }

    _isLoadingMore = false;
    _safeNotifyListeners();
  }

  Future<Product?> fetchProductDetails(int id) async {
    final cacheKey = 'product_details_$id';
    try {
      Product? cachedProduct = _cacheManager.get<Product>(cacheKey);
      if (cachedProduct != null) {
        return cachedProduct;
      }

      final response = await _connectionManager.executeWithRetry(
        () => _productApi.getProductDetails(id),
      );

      if (response != null && response.statusCode == 200) {
        final productData = json.decode(response.body);
        final product = Product.fromJson(productData);
        _cacheManager.set(cacheKey, product, ttl: const Duration(hours: 1));
        return product;
      }
    } catch (error) {
      print('Error fetching product details: $error');
    }
    return null;
  }

  // Helper per stampare stringhe lunghe senza troncamenti
  void _printLongString(String text) {
    final pattern = RegExp('.{1,800}'); // Stampa in chunks di 800 caratteri
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  // --- FILTRI ---

  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      final bool matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final bool matchesCategory = _selectedCategory.isEmpty ||
          product.categories.any((cat) => cat.name == _selectedCategory);
      return matchesSearch && matchesCategory;
    }).toList();
    _safeNotifyListeners();
  }

  List<String> get categories {
    final Set<String> categorySet = {};
    for (var product in _products) {
      for (var category in product.categories) {
        categorySet.add(category.name);
      }
    }
    return categorySet.toList();
  }

  // --- CREAZIONE PRODOTTO ---

  bool _isCreatingProduct = false;
  bool get isCreatingProduct => _isCreatingProduct;

  /// Crea un nuovo prodotto in bozza
  Future<bool> createProduct({
    required String title,
    required String description,
    required String price,
    required String category,
    List<dynamic>? images,
  }) async {
    if (_isCreatingProduct) return false;

    _isCreatingProduct = true;
    _safeNotifyListeners();

    try {
      final response = await _productApi.createProduct(
        title: title,
        description: description,
        price: price,
        category: category,
        images: images?.cast<File>(),
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Invalida la cache per forzare il refresh dei prodotti
        _cacheManager.invalidate('products_page_1');
        print('✅ Prodotto creato con successo');
        _isCreatingProduct = false;
        _safeNotifyListeners();
        return true;
      } else {
        print('❌ Errore nella creazione del prodotto');
        _isCreatingProduct = false;
        _safeNotifyListeners();
        return false;
      }
    } catch (error) {
      print('🔥 Errore durante la creazione del prodotto: $error');
      _isCreatingProduct = false;
      _safeNotifyListeners();
      return false;
    }
  }

  // --- MODIFICA PRODOTTO ---

  bool _isUpdatingProduct = false;
  bool get isUpdatingProduct => _isUpdatingProduct;

  /// Modifica un prodotto esistente
  /// Aggiorna solo i campi forniti
  Future<bool> updateProduct({
    required int productId,
    String? name,
    String? regularPrice,
    String? price,
    String? description,
    String? shortDescription,
    int? stockQuantity,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? metaData,
  }) async {
    if (_isUpdatingProduct) return false;

    _isUpdatingProduct = true;
    _safeNotifyListeners();

    try {
      final response = await _productApi.updateProduct(
        productId: productId,
        name: name,
        regularPrice: regularPrice,
        price: price,
        description: description,
        shortDescription: shortDescription,
        stockQuantity: stockQuantity,
        categories: categories,
        metaData: metaData,
      );

      if (response != null && response.statusCode == 200) {
        // Invalida la cache per forzare il refresh
        _cacheManager.invalidate('products_page_1');
        _cacheManager.invalidate('product_details_$productId');

        // Aggiorna il prodotto nella lista locale se presente
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          // Ricarica i dettagli del prodotto aggiornato
          final updatedProduct = await fetchProductDetails(productId);
          if (updatedProduct != null) {
            _products[index] = updatedProduct;
            _applyFilters();
          }
        }

        print('✅ Prodotto aggiornato con successo');
        _isUpdatingProduct = false;
        _safeNotifyListeners();
        return true;
      } else {
        print('❌ Errore nella modifica del prodotto');
        _isUpdatingProduct = false;
        _safeNotifyListeners();
        return false;
      }
    } catch (error) {
      print('🔥 Errore durante la modifica del prodotto: $error');
      _isUpdatingProduct = false;
      _safeNotifyListeners();
      return false;
    }
  }

  // --- CANCELLAZIONE PRODOTTO ---

  bool _isDeletingProduct = false;
  bool get isDeletingProduct => _isDeletingProduct;

  /// Elimina un prodotto
  /// Di default lo sposta nel cestino (trash)
  /// Usa force=true per eliminazione definitiva
  Future<bool> deleteProduct({
    required int productId,
    bool force = false,
  }) async {
    if (_isDeletingProduct) return false;

    _isDeletingProduct = true;
    _safeNotifyListeners();

    try {
      final response = await _productApi.deleteProduct(
        productId: productId,
        force: force,
      );

      if (response != null && response.statusCode == 200) {
        // Invalida la cache
        _cacheManager.invalidate('products_page_1');
        _cacheManager.invalidate('product_details_$productId');

        // Rimuovi il prodotto dalla lista locale
        _products.removeWhere((p) => p.id == productId);
        _applyFilters();

        print('✅ Prodotto eliminato con successo');
        _isDeletingProduct = false;
        _safeNotifyListeners();
        return true;
      } else {
        print('❌ Errore nella cancellazione del prodotto');
        _isDeletingProduct = false;
        _safeNotifyListeners();
        return false;
      }
    } catch (error) {
      print('🔥 Errore durante la cancellazione del prodotto: $error');
      _isDeletingProduct = false;
      _safeNotifyListeners();
      return false;
    }
  }
}
