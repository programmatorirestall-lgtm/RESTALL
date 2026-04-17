import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/models/Product.dart';
import 'package:restall/providers/Cart/cart_provider.dart';
import 'package:restall/providers/WishList.dart/wishlist_provider.dart';
import 'package:restall/constants.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  // Corretto per risolvere il warning `library_private_types_in_public_api`
  ProductCardState createState() => ProductCardState();
}

// Corretto per risolvere il warning `library_private_types_in_public_api`
class ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _wishlistController;
  late AnimationController _cartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _wishlistAnimation;
  late Animation<double> _cartAnimation;

  bool _isHovered = false;
  // Rimosso `_isPressed` perché non utilizzato

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _wishlistController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _cartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _wishlistAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _wishlistController, curve: Curves.elasticOut),
    );
    _cartAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _cartController, curve: Curves.easeInOut),
    );
  }

  bool _isMarketplaceProduct() {
    return widget.product.categories.any((category) =>
        category.name.toLowerCase() == 'marketplace' ||
        category.slug.toLowerCase() == 'marketplace');
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _wishlistController.dispose();
    _cartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha((255 * 0.3).round())
                    : Colors.black.withAlpha((255 * 0.08).round()),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => _scaleController.forward(),
              onTapUp: (_) => _scaleController.reverse(),
              onTapCancel: () => _scaleController.reverse(),
              onHover: (hovering) {
                setState(() => _isHovered = hovering);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isDark ? Colors.grey[850] : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Colors.grey[700]!.withAlpha((255 * 0.3).round())
                        : Colors.grey[200]!.withAlpha((255 * 0.5).round()),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildImageSection(isDark),
                    ),
                    _buildContentSection(isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: widget.product.images.isNotEmpty
              ? ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    widget.product.images.first.src,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    color: Colors.grey[200],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black
                    .withAlpha((255 * (_isHovered ? 0.1 : 0.05)).round()),
              ],
            ),
          ),
        ),
        Positioned(top: 12, right: 12, child: _buildWishlistButton(isDark)),
        if (widget.product.onSale)
          Positioned(top: 12, left: 12, child: _buildSaleBadge()),
        if (_isHovered)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                color: Colors.black.withAlpha((255 * 0.3).round()),
              ),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.9).round()),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.1).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Visualizza dettagli',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWishlistButton(bool isDark) {
    return Consumer<WishlistProvider>(
      builder: (ctx, wishlist, _) {
        final isInWishlist = wishlist.isInWishlist(widget.product.id);

        return AnimatedBuilder(
          animation: _wishlistAnimation,
          builder: (context, child) => Transform.scale(
            scale: _wishlistAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]!.withAlpha((255 * 0.9).round())
                    : Colors.white.withAlpha((255 * 0.95).round()),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.15).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isInWishlist
                      ? Colors.red.withAlpha((255 * 0.3).round())
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    wishlist.toggleWishlist(widget.product);
                    _wishlistController.forward().then((_) {
                      _wishlistController.reverse();
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? Colors.red : Colors.grey[600],
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[600]!, Colors.red[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withAlpha((255 * 0.3).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 12,
          ),
          SizedBox(width: 2),
          Text(
            'OFFERTA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.product.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 3),
          _buildPriceSection(isDark),
          const SizedBox(height: 6),
          _buildAddToCartButton(isDark),
        ],
      ),
    );
  }

  Widget _buildPriceSection(bool isDark) {
    return Row(
      children: [
        if (widget.product.onSale && widget.product.regularPrice > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '€${widget.product.regularPrice.toStringAsFixed(2)}',
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.red[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            '€${widget.product.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: widget.product.onSale
                  ? Colors.red[600]
                  : (isDark ? Colors.blue[300] : kPrimaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton(bool isDark) {
    final isMarketplace = _isMarketplaceProduct();

    return AnimatedBuilder(
      animation: _cartAnimation,
      builder: (context, child) => Transform.scale(
        scale: _cartAnimation.value,
        child: SizedBox(
          height: 30,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isMarketplace
                ? null
                : () async {
                    _cartController
                        .forward()
                        .then((_) => _cartController.reverse());
                    // *** CORREZIONE CRITICA QUI ***
                    Provider.of<CartProvider>(context, listen: false)
                        .addItem(widget.product);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withAlpha((255 * 0.2).round()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Aggiunto al carrello!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      widget.product.name,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withAlpha((255 * 0.9).round()),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        backgroundColor: Colors.green[600],
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isMarketplace
                  ? (isDark ? Colors.grey[700] : Colors.grey[300])
                  : (isDark ? Colors.blue[600] : kPrimaryColor),
              foregroundColor: isMarketplace
                  ? (isDark ? Colors.grey[500] : Colors.grey[600])
                  : Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 30),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                // Corretto da MaterialStateProperty
                Colors.white.withAlpha((255 * 0.1).round()),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    isMarketplace
                        ? Icons.shopping_bag_rounded
                        : Icons.add_shopping_cart_rounded,
                    size: 14),
                const SizedBox(width: 4),
                Text(
                  isMarketplace ? 'Marketplace' : 'Aggiungi',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
