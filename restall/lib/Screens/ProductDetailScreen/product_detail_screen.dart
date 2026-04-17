import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:provider/provider.dart';
import 'package:restall/API/Order/order_api.dart';
import 'package:restall/Screens/CheckOutScreen/checkout_screen.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/Product.dart';
import 'package:restall/providers/Cart/cart_provider.dart';
import 'package:restall/providers/Product/product_provider.dart';
import 'package:restall/providers/WishList.dart/wishlist_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  // ignore: library_private_types_in_public_api
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  int _quantity = 1;
  String? _selectedVariant;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final PageController _pageController = PageController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();

    // Debug: stampa le categorie del prodotto per verificare marketplace
    _checkMarketplaceCategory();
  }

  void _checkMarketplaceCategory() {
    print('🔍 DEBUG - Categorie prodotto ${widget.product.name}:');
    for (var category in widget.product.categories) {
      print('   - ID: ${category.id}, Name: "${category.name}", Slug: "${category.slug}"');
    }
    print('   È marketplace? ${_isMarketplaceProduct()}');
  }

  bool _isMarketplaceProduct() {
    return widget.product.categories.any((category) =>
      category.name.toLowerCase() == 'marketplace' ||
      category.slug.toLowerCase() == 'marketplace'
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.black54 : Colors.white70,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black54 : Colors.white70,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Consumer<WishlistProvider>(
              builder: (ctx, wishlist, _) => IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    wishlist.isInWishlist(widget.product.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(wishlist.isInWishlist(widget.product.id)),
                    color: wishlist.isInWishlist(widget.product.id)
                        ? Colors.red
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                onPressed: () {
                  wishlist.toggleWishlist(widget.product);
                  _showFeedback(
                    wishlist.isInWishlist(widget.product.id)
                        ? 'Aggiunto ai preferiti'
                        : 'Rimosso dai preferiti',
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 400,
                      pinned: false,
                      automaticallyImplyLeading: false,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildImageGallery(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildProductHeader(),
                              const SizedBox(height: 24),
                              if (widget.product.variations.isNotEmpty)
                                _buildVariants(),
                              _buildQuantitySelector(),
                              const SizedBox(height: 24),
                              if (widget.product.categories.isNotEmpty)
                                _buildCategories(),
                              _buildDescription(),
                              const SizedBox(height: 100),
                            ],
                          ),
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
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImageGallery() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.product.images.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openFullscreenImage(index),
              child: Hero(
                tag: 'product_image_${widget.product.id}_$index',
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: Image.network(
                      widget.product.images[index].src,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_outlined,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.product.images.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.product.images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withAlpha((255 * 0.5).round()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        if (widget.product.images.length > 1)
          Positioned(
            right: 16,
            top: 100,
            bottom: 60,
            child: SizedBox(
              width: 60,
              child: ListView.builder(
                itemCount: widget.product.images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _currentImageIndex == index
                            ? [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((255 * 0.2).round()),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.product.images[index].src,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_outlined,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (widget.product.onSale && widget.product.regularPrice > 0) ...[
              Text(
                '€${widget.product.regularPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[600],
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SCONTO',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '€${widget.product.price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: widget.product.onSale ? Colors.red[600] : Colors.black87,
          ),
        ),
        if (widget.product.rating > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < widget.product.rating.floor()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.product.rating.toStringAsFixed(1)} (${widget.product.ratingCount} recensioni)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVariants() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (widget.product.variations.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Varianti disponibili',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.product.variations.take(3).map((variantId) {
                final isSelected = _selectedVariant == variantId.toString();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVariant =
                          isSelected ? null : variantId.toString();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Variante $variantId',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantità',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove_rounded,
                onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  _quantity.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add_rounded,
                onTap: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.black87 : Colors.grey[400],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorie',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.product.categories.map((category) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blue.withAlpha((255 * 0.3).round()),
                  width: 1,
                ),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDescription() {
    final cleanDescription =
        widget.product.description.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    if (cleanDescription.isEmpty) return const SizedBox.shrink();

    final shouldShowReadMore = cleanDescription.length > 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descrizione',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isExpanded || !shouldShowReadMore
                ? cleanDescription
                : '${cleanDescription.substring(0, 200)}...',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ),
        if (shouldShowReadMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                _isExpanded ? 'Leggi meno' : 'Leggi tutto',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isMarketplace = _isMarketplaceProduct();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isMarketplace
                ? (isDark ? Colors.green[600] : Colors.green[500])
                : (isDark ? secondaryColor : secondaryColor),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            shadowColor: isMarketplace
                ? Colors.green.withAlpha((255 * 0.3).round())
                : secondaryColor.withAlpha((255 * 0.3).round()),
          ),
          onPressed: isMarketplace ? () => _buyNowMarketplace() : () => _addToCart(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMarketplace ? Icons.shopping_bag_rounded : Icons.shopping_cart_rounded,
                size: 20
              ),
              const SizedBox(width: 8),
              Text(
                isMarketplace ? 'Compra ora' : 'Aggiungi al carrello',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart() {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // Controlla se ci sono prodotti marketplace nel carrello
    final hasMarketplaceProducts =
        cart.items.values.any((item) => item.isMarketplace);

    if (hasMarketplaceProducts && !_isMarketplaceProduct()) {
      // Mostra dialog per svuotare il carrello
      _showMixedCartDialogForNormal(cart);
      return;
    }

    cart.addItem(widget.product, quantity: _quantity);
    _showFeedback('${widget.product.name} aggiunto al carrello');
  }

  void _showMixedCartDialogForNormal(CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            const Text('Carrello Non Compatibile'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Non puoi acquistare prodotti normali insieme a prodotti marketplace.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Vuoi svuotare il carrello e procedere con questo prodotto?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              // Svuota il carrello
              cart.clear();

              // Chiudi il dialog
              Navigator.pop(context);

              // Aggiungi il prodotto
              cart.addItem(widget.product, quantity: _quantity);
              _showFeedback('${widget.product.name} aggiunto al carrello');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Svuota e Aggiungi'),
          ),
        ],
      ),
    );
  }

  Future<void> _buyNowMarketplace() async {
    print('🛒 Acquisto marketplace per prodotto ${widget.product.id}');

    // Naviga direttamente al checkout passando il prodotto come parametro
    // Così non modifichiamo il carrello persistente dell'utente
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckOutScreen(
            isMarketplace: true,
            marketplaceProduct: widget.product,
            marketplaceQuantity: _quantity,
          ),
        ),
      );
    }
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openFullscreenImage(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageGallery(
          images: widget.product.images.map((img) => img.src).toList(),
          initialIndex: initialIndex,
          productId: widget.product.id,
        ),
      ),
    );
  }
}

class FullscreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final int productId;

  const FullscreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.productId,
  });

  @override
  State<FullscreenImageGallery> createState() => _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<FullscreenImageGallery> {
  late PageController _pageController;
  late TransformationController _transformationController;
  late int _currentIndex;
  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  bool _isZoomed() {
    final Matrix4 matrix = _transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    return scale > 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          // Solo permetti drag se non è zoomato
          if (!_isZoomed()) {
            setState(() {
              _dragOffset += details.delta.dy;
              _isDragging = true;
            });
          }
        },
        onVerticalDragEnd: (details) {
          // Se drag > 100px o velocità > 300, chiudi
          if (_dragOffset > 100 || details.velocity.pixelsPerSecond.dy > 300) {
            Navigator.pop(context);
          } else {
            // Altrimenti ritorna alla posizione originale
            setState(() {
              _dragOffset = 0.0;
              _isDragging = false;
            });
          }
        },
        child: AnimatedContainer(
          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _dragOffset, 0),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  // Reset zoom quando cambia immagine
                  _transformationController.value = Matrix4.identity();
                },
                itemBuilder: (context, index) {
                  return Hero(
                    tag: 'fullscreen_product_image_${widget.productId}_$index',
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.network(
                          widget.images[index],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.images.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.images.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? Colors.white
                                : Colors.white.withAlpha((255 * 0.5).round()),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
