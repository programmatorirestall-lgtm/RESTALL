import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:restall/API/Cart/cart.dart';
import 'package:restall/API/Shop/product.dart';
import 'package:restall/core/performance/cache_manager.dart';
import 'package:restall/core/performance/connection_manager.dart';
import 'package:restall/models/Product.dart';
import 'package:restall/models/cart_item.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class CartProvider with ChangeNotifier {
  final CartApi _cartApi;
  final ProductApi _productApi;
  final CacheManager _cacheManager;
  final ConnectionManager connectionManager;

  Map<String, CartItem> _items = {};
  bool _isLoading = true; // Inizia come true fino al caricamento iniziale
  bool _isSyncing = false;
  bool _isDisposed = false;
  static const _cartPrefsKey = 'cart_items';

  CartProvider({
    required CacheManager cacheManager,
    required this.connectionManager,
    CartApi? cartApi,
    ProductApi? productApi,
  })  : _cartApi = cartApi ?? CartApi(),
        _productApi = productApi ?? ProductApi(),
        _cacheManager = cacheManager {
    _init();
  }

  Future<void> _init() async {
    await _loadCartFromPrefs();
    // Dopo aver caricato il carrello locale, avvia la sincronizzazione con il server
    // senza bloccare l'UI.
    syncCartFromServer();
  }

  // Getters
  Map<String, CartItem> get items => {..._items};
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isEmpty => _items.isEmpty;

  double get totalAmount {
    return _items.values
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // --- AZIONI SUL CARRELLO (OFFLINE-FIRST) ---

  Future<void> addItem(Product product, {int quantity = 1}) async {
    final productId = product.id.toString();
    final isMarketplace = product.categories
        .any((cat) => cat.slug.toLowerCase() == 'marketplace');

    _items.update(
      productId,
      (existing) => existing.copyWith(quantity: existing.quantity + quantity),
      ifAbsent: () => CartItem(
        id: productId,
        title: product.name,
        price: product.price,
        quantity: quantity,
        imageUrl: product.images.isNotEmpty ? product.images.first.src : '',
        isMarketplace: isMarketplace,
      ),
    );
    _onCartChanged();
  }

  /// Aggiunge un item al carrello partendo dai suoi dettagli.
  /// Utile quando non si ha a disposizione l'intero oggetto Product.
  Future<void> addItemFromDetails({
    required String productId,
    required String title,
    required double price,
    required String imageUrl,
    int quantity = 1,
  }) async {
    _items.update(
      productId,
      (existing) => existing.copyWith(quantity: existing.quantity + quantity),
      ifAbsent: () => CartItem(
        id: productId,
        title: title,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
      ),
    );
    _onCartChanged();
  }

  Future<void> removeItem(String productId) async {
    _items.remove(productId);
    _onCartChanged();
  }

  Future<void> removeSingleItem(String productId) async {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(productId,
          (existing) => existing.copyWith(quantity: existing.quantity - 1));
    } else {
      _items.remove(productId);
    }
    _onCartChanged();
  }

  Future<void> clearCart() async {
    _items.clear();
    _onCartChanged();
  }

  /// Gestisce le operazioni da eseguire ogni volta che il carrello locale cambia.
  void _onCartChanged() {
    if (!_isDisposed) {
      notifyListeners();
    }
    _saveCartToPrefs();
    // Avvia la sincronizzazione in background senza attenderla
    if (!_isDisposed) {
      unawaited(_syncWithServer());
    }
  }

  // --- PERSISTENZA LOCALE ---

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = _items.values.map((item) => item.toJson()).toList();
    await prefs.setString(_cartPrefsKey, json.encode(cartData));
  }

  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_cartPrefsKey)) {
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
      return;
    }

    final String? cartString = prefs.getString(_cartPrefsKey);
    if (cartString != null) {
      final List<dynamic> cartData = json.decode(cartString);
      _items = {
        for (var item in cartData) item['id']: CartItem.fromJson(item),
      };
    }
    _isLoading = false;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // --- SINCRONIZZAZIONE CON IL SERVER ---

  Future<void> syncCartFromServer() async {
    if (!connectionManager.isOnline || _isDisposed) return;

    _isLoading = true;
    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      final response = await _cartApi.getCart();
      if (_isDisposed) return; // Check after async operation

      if (response != null && response.statusCode == 200) {
        final List<dynamic> serverCartData = json.decode(response.body);

        // Logica di riconciliazione (semplice: il server ha la precedenza)
        Map<String, CartItem> serverItems = {};
        for (var itemData in serverCartData) {
          if (_isDisposed) return; // Check during loop

          final productId = itemData['idProdotto'].toString();
          // Ottieni i dettagli del prodotto (cache-first)
          final product = await _fetchProductDetails(int.parse(productId));
          if (_isDisposed) return; // Check after async operation

          if (product != null) {
            serverItems[productId] = CartItem(
              id: productId,
              title: product.name,
              price: product.price,
              quantity: itemData['quantita'],
              imageUrl:
                  product.images.isNotEmpty ? product.images.first.src : '',
            );
          }
        }
        _items = serverItems;
        _onCartChanged();
      }
    } catch (e) {
      print("Errore durante la sincronizzazione del carrello dal server: $e");
    }

    if (_isDisposed) return; // Check before final notifyListeners
    _isLoading = false;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> _syncWithServer() async {
    if (_isSyncing || !connectionManager.isOnline || _isDisposed) return;

    _isSyncing = true;
    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      final cartData = {
        "cart": {
          "items": _items.values
              .map((item) => {
                    "idProdotto": int.parse(item.id),
                    "quantita": item.quantity,
                    "prezzo": item.price,
                  })
              .toList(),
        }
      };
      await connectionManager.executeWithRetry(
        () => _cartApi.addCart(cartData),
      );
      if (_isDisposed) return; // Check after async operation
    } catch (e) {
      print("Sincronizzazione carrello fallita: $e");
      // Qui si potrebbe implementare una logica di "dirty flag" per riprovare più tardi
    }

    if (_isDisposed) return; // Check before final notifyListeners
    _isSyncing = false;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<Product?> _fetchProductDetails(int id) async {
    final cacheKey = 'product_details_$id';
    Product? product = _cacheManager.get<Product>(cacheKey);
    if (product != null) return product;

    try {
      final response = await _productApi.getProductDetails(id);
      if (response != null && response.statusCode == 200) {
        product = Product.fromJson(json.decode(response.body));
        _cacheManager.set(cacheKey, product, ttl: const Duration(hours: 1));
        return product;
      }
    } catch (e) {
      print("Errore fetch dettagli prodotto per il carrello: $e");
    }
    return null;
  }

  // --- METODI PUBBLICI DI UTILITA' (API PRECEDENTE) ---

  /// Alias per `clearCart` per mantenere la compatibilità.
  Future<void> clear() => clearCart();

  /// Restituisce la quantità di un singolo prodotto nel carrello.
  int getProductQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  /// Controlla se un prodotto è presente nel carrello.
  bool containsProduct(String productId) {
    return _items.containsKey(productId);
  }

  /// Restituisce un [CartItem] specifico dal carrello.
  CartItem? getItem(String productId) {
    return _items[productId];
  }

  /// Aggiorna la quantità di un prodotto a un valore specifico.
  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (!_items.containsKey(productId)) return;

    if (newQuantity > 0) {
      _items.update(productId, (item) => item.copyWith(quantity: newQuantity));
      _onCartChanged();
    } else {
      // Se la quantità è 0 o meno, rimuovi l'item.
      await removeItem(productId);
    }
  }

  // --- METODI DI CHECKOUT ---

  Future<void> checkoutWithStripeSheet(BuildContext context) async {
    if (!connectionManager.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nessuna connessione di rete.")),
      );
      return;
    }

    try {
      final response = await _cartApi.createOrderOnly();
      if (response.statusCode != 200) {
        throw Exception('Errore nella creazione del PaymentIntent');
      }

      final data = jsonDecode(response.body);
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: data['paymentIntent'],
          merchantDisplayName: 'RestAll',
          customerId: data['customer'],
          customerEphemeralKeySecret: data['ephemeralKey'],
          style: ThemeMode.light,
          allowsDelayedPaymentMethods: true,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento completato con successo!')),
      );
      await clearCart(); // Svuota il carrello con il nuovo metodo
    } on StripeException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Errore Stripe: ${e.error.localizedMessage ?? 'Errore sconosciuto'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Si è verificato un errore: $e')),
      );
    }
  }

  Future<bool> checkout(String paymentMethod) async {
    if (!connectionManager.isOnline) return false;

    try {
      final response = await connectionManager.executeWithRetry(
          () => _cartApi.createOrderWithPayment(paymentMethod));

      if (response.statusCode == 200) {
        await clearCart();
        return true;
      }
      return false;
    } catch (e) {
      print("Errore durante il checkout: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
