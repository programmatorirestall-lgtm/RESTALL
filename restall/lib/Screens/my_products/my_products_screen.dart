import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/API/User/user.dart';
import 'package:restall/models/UserProducts.dart';
import 'package:restall/providers/Product/product_provider.dart';
import 'package:restall/Screens/edit_product/edit_product_screen.dart';
import 'package:restall/Screens/sell_product/sell_product_screen.dart';
import 'package:restall/constants.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({Key? key}) : super(key: key);

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserApi _userApi = UserApi();

  bool _isLoading = false;
  bool _isFetching = false;  // Flag separato per prevenire chiamate concorrenti
  UserProductsResponse? _productsData;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('📍 DEBUG MyProducts: initState() chiamato');
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      print('🔄 DEBUG MyProducts: Tab cambiato - index: ${_tabController.index}');
    });
    _loadProducts();
  }

  @override
  void didUpdateWidget(MyProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('⚠️ DEBUG MyProducts: didUpdateWidget() chiamato - REBUILD RILEVATO');
  }

  Future<void> _loadProducts() async {
    // Timestamp per tracciare le chiamate
    final callTime = DateTime.now();
    print('🕐 DEBUG MyProducts: _loadProducts() chiamato alle ${callTime.hour}:${callTime.minute}:${callTime.second}.${callTime.millisecond}');
    print('📊 DEBUG MyProducts: StackTrace:');
    print(StackTrace.current.toString().split('\n').take(5).join('\n'));

    // Evita chiamate multiple simultanee
    if (_isFetching) {
      print('⚠️ DEBUG MyProducts: Fetch già in corso, skip');
      return;
    }

    print('🚀 DEBUG MyProducts: Inizio _loadProducts()');
    _isFetching = true;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 DEBUG MyProducts: Chiamata a getUserProducts...');
      print('📍 DEBUG MyProducts: Endpoint: /api/v1/shop/user/prodotto');

      final data = await _userApi.getUserProducts();

      print('✅ DEBUG MyProducts: Risposta ricevuta');
      print('📦 DEBUG MyProducts: Draft count: ${data.draft.length}');
      print('📦 DEBUG MyProducts: Published count: ${data.published.length}');
      print('📦 DEBUG MyProducts: Sold count: ${data.sold.length}');

      // Debug: mostra dettagli dei primi prodotti
      if (data.draft.isNotEmpty) {
        final first = data.draft.first;
        print('🔍 DEBUG MyProducts: Primo draft - ID: ${first.id}, Nome: "${first.name}", Prezzo: "€${first.price}"');
      }
      if (data.published.isNotEmpty) {
        final first = data.published.first;
        print('🔍 DEBUG MyProducts: Primo published - ID: ${first.id}, Nome: "${first.name}", Prezzo: "€${first.price}"');
      }

      if (mounted) {
        setState(() {
          _productsData = data;
          _isLoading = false;
        });
      }

      print('✅ DEBUG MyProducts: State aggiornato con successo');
    } catch (e) {
      print('❌ DEBUG MyProducts: Errore nel caricamento prodotti: $e');
      print('❌ DEBUG MyProducts: Stack trace: ${StackTrace.current}');

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      _isFetching = false;
      print('🏁 DEBUG MyProducts: Fine _loadProducts(), _isFetching resettato');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // === METODI PER MODIFICA E CANCELLAZIONE ===

  /// Mostra dialog di conferma per eliminazione prodotto
  Future<void> _showDeleteConfirmation(ProductBase product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Conferma eliminazione',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sei sicuro di voler eliminare questo prodotto?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (product.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        product.images.first.src,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 24),
                          );
                        },
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '€ ${product.price}',
                          style: TextStyle(
                            color: secondaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Il prodotto verrà spostato nel cestino.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _deleteProduct(product.id);
    }
  }

  /// Elimina un prodotto
  Future<void> _deleteProduct(int productId) async {
    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Eliminazione in corso...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      final success = await productProvider.deleteProduct(
        productId: productId,
        force: false, // Sposta nel cestino, non elimina definitivamente
      );

      if (!mounted) return;

      // Chiudi loading dialog
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prodotto eliminato con successo'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Ricarica i prodotti
        await _loadProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'eliminazione del prodotto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Chiudi loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Naviga alla schermata di modifica prodotto
  Future<void> _navigateToEditProduct(ProductBase product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );

    // Se il prodotto è stato modificato con successo, ricarica la lista
    if (result == true && mounted) {
      await _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔨 DEBUG MyProducts: build() chiamato - isLoading: $_isLoading, isFetching: $_isFetching, hasData: ${_productsData != null}');

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                secondaryColor.withValues(alpha: 0.9),
                secondaryColor.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        title: const Text(
          'I Miei Prodotti',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Bozze', icon: Icon(Icons.edit_outlined, size: 20)),
            Tab(text: 'Pubblicati', icon: Icon(Icons.check_circle_outline, size: 20)),
            Tab(text: 'Venduti', icon: Icon(Icons.local_shipping_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDraftProducts(),
          _buildPublishedProducts(),
          _buildSoldProducts(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, SellProductScreen.routeName);
        },
        icon: Icon(Icons.add, color: secondaryColor),
        label: Text(
          'Nuovo Prodotto',
          style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 6,
      ),
    );
  }

  Widget _buildDraftProducts() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final products = _productsData?.draft ?? [];

    if (products.isEmpty) {
      return _buildEmptyState(
        icon: Icons.edit_note_rounded,
        title: 'Nessuna bozza',
        subtitle: 'I tuoi prodotti in bozza appariranno qui',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildPublishedProducts() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final products = _productsData?.published ?? [];

    if (products.isEmpty) {
      return _buildEmptyState(
        icon: Icons.storefront_rounded,
        title: 'Nessun prodotto pubblicato',
        subtitle: 'I tuoi prodotti in vendita appariranno qui',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildSoldProducts() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final products = _productsData?.sold ?? [];

    if (products.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sell_rounded,
        title: 'Nessun prodotto venduto',
        subtitle: 'I prodotti che hai venduto appariranno qui',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildSoldProductCard(product);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Errore nel caricamento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Errore sconosciuto',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductBase product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Navigazione ai dettagli del prodotto
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Immagine prodotto
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first.src,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              // Info prodotto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '€ ${product.price}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (product.stockQuantity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.stockQuantity! > 0
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Stock: ${product.stockQuantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.stockQuantity! > 0
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Menu a 3 pallini
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToEditProduct(product);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(product);
                  }
                },
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: secondaryColor),
                        const SizedBox(width: 12),
                        const Text('Modifica'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text('Elimina'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoldProductCard(SoldProduct product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Card del prodotto base
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () {
              // TODO: Navigazione ai dettagli del prodotto
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Immagine prodotto
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.images.isNotEmpty
                        ? Image.network(
                            product.images.first.src,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Info prodotto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '€ ${product.price}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Venduti: ${product.totalSold}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sezione ordini
          if (product.orders.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ordini (${product.orders.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...product.orders.take(3).map((order) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.customer.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Qtà: ${order.quantity} • € ${order.total}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: order.status == 'completed'
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.status == 'completed'
                                  ? 'Completato'
                                  : 'In lavorazione',
                              style: TextStyle(
                                fontSize: 11,
                                color: order.status == 'completed'
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (product.orders.length > 3)
                    Text(
                      'e altri ${product.orders.length - 3} ordini...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
