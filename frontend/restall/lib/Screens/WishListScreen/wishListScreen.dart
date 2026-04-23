import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/Product.dart';
import 'package:restall/providers/WishList.dart/wishlist_provider.dart';
import 'package:restall/Screens/details_product/details_product_screen.dart';
import 'components/wishlist_product_card.dart';
import 'components/wishlist_stats_card.dart';

class WishlistScreen extends StatefulWidget {
  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                secondaryColor.withOpacity(0.9),
                secondaryColor.withOpacity(0.7),
              ],
            ),
          ),
        ),
        title: const Text(
          'Wishlist',
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
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<WishlistProvider>(
          builder: (context, wishlistProvider, child) {
            if (wishlistProvider.isLoading && !wishlistProvider.isInitialized) {
              return _buildLoadingState();
            }

            if (wishlistProvider.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildStatsHeader(wishlistProvider),
                _buildFilterBar(wishlistProvider),
                Expanded(
                  child: _buildProductGrid(wishlistProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Caricamento wishlist...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline_rounded,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'La tua wishlist è vuota',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Aggiungi i prodotti che ti piacciono\nper trovarli facilmente qui!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(WishlistProvider wishlistProvider) {
    return Container(
      margin: EdgeInsets.all(16),
      child: WishlistStatsCard(
        itemCount: wishlistProvider.itemCount,
        stats: wishlistProvider.stats,
      ),
    );
  }

  Widget _buildFilterBar(WishlistProvider wishlistProvider) {
    final categories = <String>['all'];

    // Estrai categorie uniche dai prodotti
    for (final product in wishlistProvider.items) {
      for (final category in product.categories) {
        if (!categories.contains(category.name.toLowerCase())) {
          categories.add(category.name.toLowerCase());
        }
      }
    }

    if (categories.length <= 1) return SizedBox.shrink();

    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _currentFilter == category;
          final displayName = category == 'all' ? 'Tutti' : category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentFilter = category;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? secondaryColor : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? secondaryColor : Colors.grey[300]!,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: secondaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  displayName.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(WishlistProvider wishlistProvider) {
    final filteredProducts = _currentFilter == 'all'
        ? wishlistProvider.itemsSortedByNewest
        : wishlistProvider.getItemsByCategory(_currentFilter);

    return RefreshIndicator(
      onRefresh: wishlistProvider.refreshWishlist,
      color: secondaryColor,
      backgroundColor: Colors.white,
      child: filteredProducts.isEmpty
          ? _buildEmptyFilterState()
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return WishlistProductCard(
                  product: product,
                  onTap: () => _navigateToProductDetail(product),
                  onRemove: () => _removeFromWishlist(product),
                );
              },
            ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Nessun prodotto in questa categoria',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProductDetail(Product product) {
    Navigator.pushNamed(
      context,
      DetailsProductScreen.routeName,
      arguments: product,
    );
  }

  void _removeFromWishlist(Product product) {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    wishlistProvider.removeItem(product.id);

    // Mostra feedback all'utente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.heart_broken, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('${product.name} rimosso dai preferiti'),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'ANNULLA',
          textColor: Colors.white,
          onPressed: () {
            wishlistProvider.addItem(product);
          },
        ),
      ),
    );
  }
}
