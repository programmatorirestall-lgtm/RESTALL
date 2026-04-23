import 'package:flutter/material.dart' hide kToolbarHeight;
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/Product.dart';
import 'package:restall/providers/Cart/cart_provider.dart';
import 'package:restall/providers/WishList.dart/wishlist_provider.dart';
import 'package:restall/Screens/details_product/components/product_images.dart';

class DetailsProductScreen extends StatefulWidget {
  static String routeName = "/details";
  final int? productId;

  const DetailsProductScreen({super.key, this.productId});

  @override
  State<DetailsProductScreen> createState() => _DetailsProductScreenState();
}

class _DetailsProductScreenState extends State<DetailsProductScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabController;
  late AnimationController _wishlistController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;
  late Animation<double> _wishlistScaleAnimation;

  bool _isExpanded = false;
  int _quantity = 1;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _wishlistController = AnimationController(
      duration: fastDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));

    _wishlistScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _wishlistController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    _wishlistController.dispose();
    super.dispose();
  }

  Future<void> _addToCart(Product product) async {
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);
    HapticFeedback.mediumImpact();

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      // *** CORREZIONE CRITICA QUI ***
      await cartProvider.addItem(product, quantity: _quantity);

      _showSuccessSnackBar(product.name);

      _fabController.reverse().then((_) {
        _fabController.forward();
      });
    } catch (error) {
      _showErrorSnackBar('Errore durante l\'aggiunta al carrello');
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  void _toggleWishlist(Product product) {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    wishlistProvider.toggleWishlist(product);

    _wishlistController.forward().then((_) {
      _wishlistController.reverse();
    });

    HapticFeedback.lightImpact();
  }

  void _showSuccessSnackBar(String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: successColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$productName aggiunto al carrello!',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Vedi Carrello',
          textColor: primaryColor,
          onPressed: () {
            // Navigate to cart
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: errorColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Product;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kBackgroundColor,
      appBar: _buildModernAppBar(args),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: kToolbarHeight + 40),
                    ProductImages(product: args),
                    const SizedBox(height: largePadding),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _buildProductInfoCard(args),
              ),
              SliverToBoxAdapter(
                child: _buildDescriptionCard(args),
              ),
              SliverToBoxAdapter(
                child: _buildSpecsCard(args),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100), // Space for FAB
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingWishlistButton(args),
      bottomNavigationBar: _buildStickyBottomBar(args),
    );
  }

  PreferredSizeWidget _buildModernAppBar(Product product) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((255 * 0.9).round()),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: secondaryColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((255 * 0.9).round()),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.1).round()),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: secondaryColor,
              size: 20,
            ),
            onPressed: () {
              // Share functionality
              HapticFeedback.lightImpact();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfoCard(Product product) {
    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      padding: const EdgeInsets.all(largePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kTextColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (product.rating > 0) ...[
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < product.rating.floor()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 18,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '${product.rating.toStringAsFixed(1)} (${product.ratingCount} recensioni)',
                  style: TextStyle(
                    color: kLightTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              if (product.regularPrice != product.price) ...[
                Text(
                  '€${product.regularPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: kLightTextColor,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: errorColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${(((product.regularPrice - product.price) / product.regularPrice) * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withAlpha((255 * 0.3).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '€${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: buttonTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: product.stockStatus == 'instock'
                      ? successColor
                      : errorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                product.stockStatus == 'instock'
                    ? 'Disponibile'
                    : 'Non disponibile',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: product.stockStatus == 'instock'
                      ? successColor
                      : errorColor,
                ),
              ),
              const Spacer(),
              if (product.stockQuantity > 0 && product.stockQuantity <= 10)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: warningColor.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Solo ${product.stockQuantity} rimasti',
                    style: const TextStyle(
                      color: warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildQuantitySelector(),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantità',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kTextColor,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: kPrimaryLightColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryColor.withAlpha((255 * 0.2).round()),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove_rounded,
                onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  _quantity.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
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
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: onTap != null ? primaryColor : Colors.grey[400],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(Product product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      padding: const EdgeInsets.all(largePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Descrizione',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() => _isExpanded = !_isExpanded);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryLightColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'Riduci' : 'Espandi',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: defaultDuration,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: primaryColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedCrossFade(
            duration: defaultDuration,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Html(
              data: product.description,
              style: {
                "body": Style(
                  fontSize: FontSize(14),
                  color: kSecondaryTextColor,
                  lineHeight: const LineHeight(1.5),
                  maxLines: 3,
                  textOverflow: TextOverflow.ellipsis,
                ),
              },
            ),
            secondChild: Html(
              data: product.description,
              style: {
                "body": Style(
                  fontSize: FontSize(14),
                  color: kSecondaryTextColor,
                  lineHeight: const LineHeight(1.5),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsCard(Product product) {
    if (product.categories.isEmpty && product.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      padding: const EdgeInsets.all(largePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dettagli Prodotto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 16),
          if (product.categories.isNotEmpty) ...[
            _buildDetailRow(
              'Categoria',
              product.categories.map((cat) => cat.name).join(', '),
            ),
            const SizedBox(height: 12),
          ],
          if (product.sku.isNotEmpty) ...[
            _buildDetailRow('SKU', product.sku),
            const SizedBox(height: 12),
          ],
          if (product.weight.isNotEmpty) ...[
            _buildDetailRow('Peso', '${product.weight} kg'),
            const SizedBox(height: 12),
          ],
          if (product.tags.isNotEmpty) ...[
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.tags.take(6).map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryLightColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withAlpha((255 * 0.2).round()),
                    ),
                  ),
                  child: Text(
                    tag.name,
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: kLightTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: kTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingWishlistButton(Product product) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, _) {
        final isInWishlist = wishlistProvider.isInWishlist(product.id);

        return AnimatedBuilder(
          animation: _wishlistScaleAnimation,
          child: FloatingActionButton(
            heroTag: "wishlist",
            backgroundColor: isInWishlist ? errorColor : Colors.white,
            foregroundColor: isInWishlist ? Colors.white : errorColor,
            elevation: 8,
            onPressed: () => _toggleWishlist(product),
            child: AnimatedSwitcher(
              duration: fastDuration,
              child: Icon(
                isInWishlist
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isInWishlist),
                size: 24,
              ),
            ),
          ),
          builder: (context, child) {
            return Transform.scale(
              scale: _wishlistScaleAnimation.value,
              child: child,
            );
          },
        );
      },
    );
  }

  Widget _buildStickyBottomBar(Product product) {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - _fabAnimation.value)),
          child: Container(
            padding: EdgeInsets.only(
              left: largePadding,
              right: largePadding,
              top: defaultPadding,
              bottom: MediaQuery.of(context).padding.bottom + defaultPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(kBorderRadius),
                topRight: Radius.circular(kBorderRadius),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.1).round()),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Totale',
                        style: TextStyle(
                          fontSize: 12,
                          color: kLightTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '€${(product.price * _quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: AnimatedContainer(
                      duration: fastDuration,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            _isAddingToCart || product.stockStatus != 'instock'
                                ? null
                                : () => _addToCart(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: buttonTextColor,
                          elevation: 8,
                          shadowColor: primaryColor.withAlpha((255 * 0.3).round()),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isAddingToCart
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      buttonTextColor),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart_rounded,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    product.stockStatus == 'instock'
                                        ? 'Aggiungi al Carrello'
                                        : 'Non Disponibile',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
