import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:restall/API/Shop/product.dart';
import 'package:restall/API/Order/order_api.dart';
import 'package:restall/API/User/user.dart';
import 'package:restall/Screens/OpenTicket/ticket_screen.dart';
import 'package:restall/Screens/SideBar/sidebar.dart';
import 'package:restall/Screens/unified_tickets_screen.dart';
import 'package:restall/providers/Cart/cart_provider.dart';
import 'package:restall/providers/WishList.dart/wishlist_provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/Screens/shop/shop_screen.dart';
import 'package:restall/Screens/ProductDetailScreen/product_detail_screen.dart';
import 'package:restall/models/Product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final ProductApi _productApi = ProductApi();
  final OrderApi _orderApi = OrderApi();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _statsController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _statsAnimation;

  // Data state
  List<dynamic> _offerProducts = [];
  List<dynamic> _recentOrders = [];
  Map<String, dynamic> _userStats = {};
  List<Map<String, dynamic>> _newsItems = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _userName = "";
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;
  PageController _carouselController = PageController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initNewsData();
    _loadUserData();
    _loadDashboardData();
    _startCarouselAutoScroll();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _statsController.dispose();
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

// Funzione helper per convertire valori API in double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  void _initNewsData() {
    _newsItems = [
      {
        'title': 'Nuova partnership con Amazon',
        'subtitle': 'Espandiamo la nostra rete di distribuzione',
        'date': 'Oggi',
        'icon': Icons.handshake_rounded,
        'color': Colors.blue,
      },
      {
        'title': 'Update app v2.1 disponibile',
        'subtitle': 'Nuove funzionalità per il tracking ordini',
        'date': '2 giorni fa',
        'icon': Icons.system_update_rounded,
        'color': Colors.green,
      },
      {
        'title': 'Black Friday: sconti fino al 70%',
        'subtitle': 'Non perdere le offerte esclusive',
        'date': '1 settimana fa',
        'icon': Icons.local_offer_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Nuovo centro assistenza attivo',
        'subtitle': 'Supporto tecnico 24/7 per tutti i clienti',
        'date': '2 settimane fa',
        'icon': Icons.support_agent_rounded,
        'color': Colors.purple,
      },
    ];
  }

  void _startCarouselAutoScroll() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_offerProducts.isNotEmpty && mounted) {
        final nextIndex = (_currentCarouselIndex + 1) % _offerProducts.length;
        _carouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userProfile = await UserApi().getData();
      if (userProfile != null && mounted) {
        setState(() {
          _userName = userProfile.nome ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      await Future.wait([
        _loadOfferProducts(),
        _loadRecentOrders(),
        _loadUserStats(),
      ]);

      setState(() {
        _isLoading = false;
      });

      // Start staggered animations
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _slideController.reset();
        _slideController.forward();
        _statsController.forward();
      }
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<bool> _loadOfferProducts() async {
    try {
      final response = await _productApi.getProducts();
      if (response?.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            // Simula prodotti in offerta - in produzione filtrare per campo discount
            _offerProducts = data.take(8).map((product) {
              // Simula prezzi scontati
              final originalPrice = (product['price'] ?? 100.0) * 1.3;
              product['originalPrice'] = originalPrice;
              product['discountPercentage'] =
                  ((originalPrice - (product['price'] ?? 100.0)) /
                          originalPrice *
                          100)
                      .round();
              return product;
            }).toList();
          });
          return true;
        }
      }
    } catch (e) {
      print('Error loading offer products: $e');
    }

    setState(() {
      _offerProducts = [];
    });
    return false;
  }

  Future<bool> _loadRecentOrders() async {
    try {
      final response = await _orderApi.getOrders();
      if (response?.statusCode == 200) {
        final data = jsonDecode(response!.body);
        if (data is List) {
          setState(() {
            _recentOrders = data.take(3).toList();
          });
          return true;
        }
      }
    } catch (e) {
      print('Error loading recent orders: $e');
    }

    setState(() {
      _recentOrders = [];
    });
    return false;
  }

  Future<bool> _loadUserStats() async {
    setState(() {
      _userStats = {
        'totalOrders': _recentOrders.length + 15, // Simula dati storici
        'totalSpent': 1245.50,
        'memberSince': '2024',
        'loyaltyPoints': 2850,
        'monthlyOrders': 8,
        'savedAmount': 185.30,
      };
    });
    return true;
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);

    await Future.wait([
      _loadDashboardData(),
      cartProvider.syncCartFromServer(),
      wishlistProvider.refreshWishlist(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _onRefresh,
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
                ? _buildErrorState()
                : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Caricamento dashboard...',
            style: TextStyle(
              color: kTextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Qualcosa è andato storto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Non è stato possibile caricare la dashboard',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Riprova'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            _buildWelcomeHeader(),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 30),

            // News Section
            // _buildNewsSection(),
            // const SizedBox(height: 30),

            // Offer Products Carousel
            // _buildOfferProductsCarousel(),
            // const SizedBox(height: 30),

            // Enhanced User Stats
            //   _buildEnhancedUserStats(),
            //   const SizedBox(height: 30),

            //   // Recent Orders
            //   _buildRecentOrdersSection(),
            //   const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.1),
              accentCanvasColor.withOpacity(0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ciao${_userName.isNotEmpty ? ', $_userName' : ''}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestisci i tuoi ticket!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Azioni Rapide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              // _buildActionCard(
              //   title: 'Shop',
              //   subtitle: 'Esplora prodotti',
              //   icon: Icons.shopping_bag_outlined,
              //   gradient: const LinearGradient(
              //     colors: [primaryColor, accentCanvasColor],
              //   ),
              //   onTap: () => _navigateToTab(6), // Index del shop nella sidebar
              // ),
              _buildActionCard(
                title: 'Apri Ticket',
                subtitle: 'Supporto tecnico',
                icon: Icons.support_agent_rounded,
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                ),
                onTap: () => _navigateToTab(0), // Index ticket
              ),
              _buildActionCard(
                title: 'I Miei Ticket',
                subtitle: 'Controlla stato',
                icon: Icons.assignment_outlined,
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[400]!],
                ),
                onTap: () => _navigateToTab(1), // Index my tickets
              ),
              _buildActionCard(
                title: 'Network',
                subtitle: 'Gestisci rete',
                icon: Icons.group_outlined,
                gradient: LinearGradient(
                  colors: [Colors.orange[600]!, Colors.orange[400]!],
                ),
                onTap: () => _navigateToTab(4), // Index network
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToTab(int index) {
    // Naviga direttamente alla schermata specifica
    switch (index) {
      case 0: // Apri Ticket
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TicketScreen()),
        );
        break;
      case 1: // I Miei Ticket
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SideBar(initialTabIndex: 2)),
        );
        break;
      case 4: // Network
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SideBar(initialTabIndex: 5)),
        );
        break;
      case 6: // Shop
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SideBar(initialTabIndex: 6)),
        );
        break;
    }
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 100,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ultime Novità',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full news screen
                },
                child: const Text('Vedi tutte'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _newsItems.take(3).length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final news = _newsItems[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset((1 - value) * 50, 0),
                    child: Opacity(
                      opacity: value,
                      child: _buildNewsItem(news),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(Map<String, dynamic> news) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (news['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              news['icon'] as IconData,
              color: news['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  news['subtitle'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            news['date'],
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferProductsCarousel() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔥 Offerte Speciali',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              if (_offerProducts.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ShopScreen()),
                  ),
                  child: const Text('Vedi tutte'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_offerProducts.isNotEmpty) ...[
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _carouselController,
                onPageChanged: (index) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
                itemCount: _offerProducts.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildOfferProductCard(_offerProducts[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _offerProducts.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentCarouselIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentCarouselIndex == index
                        ? primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ] else
            _buildEmptyOffers(),
        ],
      ),
    );
  }

  Widget _buildOfferProductCard(dynamic product) {
    final originalPrice = product['originalPrice'] ?? 0.0;
    final currentPrice = product['price'] ?? 0.0;
    final discountPercentage = product['discountPercentage'] ?? 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Navigate to product detail
        try {
          final productObj = Product.fromJson(product);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: productObj),
            ),
          );
        } catch (e) {
          print('Error navigating to product detail: $e');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kCardShadow,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: product['images'] != null &&
                              (product['images'] as List).isNotEmpty
                          ? Image.network(
                              product['images'][0]['src'] ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 50,
                                  color: Colors.grey[400],
                                );
                              },
                            )
                          : Icon(
                              Icons.image_not_supported_rounded,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                ),
                // Product info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'Prodotto',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: kTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              '€${currentPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '€${originalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Discount badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '-$discountPercentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOffers() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Nessuna offerta disponibile',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Torna presto per nuove promozioni!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedUserStats() {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statsAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Le Tue Statistiche',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildStatCard(
                    title: 'Ordini Totali',
                    value: '${_userStats['totalOrders'] ?? 0}',
                    icon: Icons.shopping_bag_rounded,
                    color: Colors.blue,
                    progress: _parseDouble(_userStats['totalOrders']) / 50.0,
                  ),
                  _buildStatCard(
                    title: 'Spesa Totale',
                    value:
                        '€${_parseDouble(_userStats['totalSpent']).toStringAsFixed(0)}',
                    icon: Icons.euro_symbol_rounded,
                    color: Colors.green,
                    progress: _parseDouble(_userStats['totalSpent']) / 2000.0,
                  ),
                  _buildStatCard(
                    title: 'Punti Fedeltà',
                    value: '${_userStats['loyaltyPoints'] ?? 0}',
                    icon: Icons.stars_rounded,
                    color: Colors.orange,
                    progress:
                        _parseDouble(_userStats['loyaltyPoints']) / 5000.0,
                  ),
                  _buildStatCard(
                    title: 'Risparmiato',
                    value:
                        '€${_parseDouble(_userStats['savedAmount']).toStringAsFixed(0)}',
                    icon: Icons.savings_rounded,
                    color: Colors.purple,
                    progress: _parseDouble(_userStats['savedAmount']) / 500.0,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                '${(progress.clamp(0.0, 1.0) * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ordini Recenti',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              if (_recentOrders.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Navigate to orders screen
                  },
                  child: const Text('Vedi tutti'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentOrders.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentOrders.take(3).length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = _recentOrders[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset((1 - value) * 50, 0),
                      child: Opacity(
                        opacity: value,
                        child: _buildOrderItem(order),
                      ),
                    );
                  },
                );
              },
            )
          else
            _buildEmptyOrders(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(dynamic order) {
    final status = order['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ordine #${order['id'] ?? 'N/A'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: kTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Totale: €${_parseDouble(order['total']).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (order['date'] != null)
            Text(
              'Data: ${order['date']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrders() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Nessun ordine recente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'I tuoi ordini appariranno qui',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'processing':
      case 'shipped':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completato';
      case 'delivered':
        return 'Consegnato';
      case 'processing':
        return 'In elaborazione';
      case 'shipped':
        return 'Spedito';
      case 'pending':
        return 'In attesa';
      case 'cancelled':
        return 'Annullato';
      default:
        return 'Sconosciuto';
    }
  }
}
