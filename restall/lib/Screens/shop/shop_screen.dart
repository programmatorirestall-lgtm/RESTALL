import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/Screens/Auction/auction_screen.dart';
import 'package:restall/Screens/account/account_screen.dart';
import 'package:restall/Screens/cart/cart_screen.dart';
import 'package:restall/Screens/products/products_screen.dart';
import 'package:restall/components/seller_verification_dialog.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/Cart/cart_provider.dart';
import 'package:restall/providers/Product/product_provider.dart';
import 'package:restall/providers/Profile/profile_provider.dart';
import 'package:restall/providers/ShopNavigation/shop_navigation_provider.dart';

class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Per gestire il doppio tap
  int? _lastTappedIndex;
  DateTime? _lastTapTime;

  final List<Widget> _screens = [
    ProductsScreen(),
    AuctionsScreen(),
    CartScreen(),
    const AccountScreen(),
  ];

  // Mappa gli indici della bottom bar agli indici delle schermate
  int _getScreenIndex(int bottomBarIndex) {
    // Bottom bar: Prodotti(0), Aste(1), Vendi(2), Carrello(3), Account(4)
    // Schermate: Prodotti(0), Aste(1), Carrello(2), Account(3)
    // Il pulsante "Vendi"(2) apre una nuova schermata, quindi salta l'indice
    if (bottomBarIndex < 2) return bottomBarIndex;
    if (bottomBarIndex == 2) return 0; // Default, non dovrebbe essere usato
    return bottomBarIndex - 1; // Carrello(3)→2, Account(4)→3
  }

  final List<IconData> _icons = [
    Icons.storefront_rounded,
    Icons.gavel_rounded,
    Icons.add, // Pulsante centrale per vendere
    Icons.shopping_bag_rounded,
    Icons.person_rounded,
  ];

  // Titoli per la sidebar
  final List<String> _sidebarTitles = [
    'Prodotti',
    'Aste',
    'Vendi',
    'Carrello',
    'Account',
  ];

  void _updateSidebarTitle() {
    if (!mounted) return;
    try {
      final shopNavProvider =
          Provider.of<ShopNavigationProvider>(context, listen: false);
      shopNavProvider.updateShopSection(_sidebarTitles[_selectedIndex]);
    } catch (e) {
      // Provider non disponibile, ignora l'errore
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // I dati vengono ora caricati automaticamente dai rispettivi provider
    // all'inizializzazione (ProductProvider e CartProvider si auto-inizializzano).
    Future.delayed(Duration.zero, () {
      if (!mounted) return;

      // Aggiorna il titolo della sidebar
      _updateSidebarTitle();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) async {
    // Se è il pulsante centrale (index 2), verifica seller prima di procedere
    if (index == 2) {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

      // Aspetta che il ProfileProvider completi il loading se necessario
      if (profileProvider.state == ProfileState.loading) {
        print('⏳ DEBUG ShopScreen: Aspetto completamento fetchProfile...');
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return profileProvider.state == ProfileState.loading;
        });
        print('✅ DEBUG ShopScreen: fetchProfile completato');
      }

      print('🔍 DEBUG ShopScreen: isSellerVerified = ${profileProvider.isSellerVerified}');
      print('📊 DEBUG ShopScreen: sellerStatus = ${profileProvider.userProfile?.sellerStatus}');

      // Check mounted before using context
      if (!mounted) return;

      // Check se l'utente è un venditore verificato
      if (!profileProvider.isSellerVerified) {
        showSellerVerificationDialog(context);
        return;
      }

      Navigator.pushNamed(context, '/sell-product');
      return;
    }

    // Controllo doppio tap per refresh
    final now = DateTime.now();
    if (_lastTappedIndex == index &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      // Doppio tap rilevato!
      print('🔄 Doppio tap su tab $index - Ricarico i dati');
      _refreshCurrentScreen(index);
      _lastTappedIndex = null;
      _lastTapTime = null;
      return;
    }

    _lastTappedIndex = index;
    _lastTapTime = now;

    if (index != _selectedIndex) {
      _animationController.reverse().then((_) {
        setState(() {
          _selectedIndex = index;
        });
        _animationController.forward();

        // Aggiorna il titolo della sidebar
        _updateSidebarTitle();
      });
    }
  }

  void _refreshCurrentScreen(int index) {
    // Ricarica i dati in base al tab selezionato
    if (index == 0) {
      // Prodotti (index 0)
      print('🔄 Ricarico i prodotti...');
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(refresh: true);
    } else if (index == 1) {
      // Aste (index 1)
      print('🔄 Ricarico le aste...');
      // Qui potresti aggiungere il refresh delle aste se hai un provider per le aste
    } else if (index == 3) {
      // Carrello (index 3)
      print('🔄 Ricarico il carrello...');
      Provider.of<CartProvider>(context, listen: false).syncCartFromServer();
    }

    // Mostra un feedback all'utente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Ricaricamento in corso...'),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _animationController.forward();

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * _animation.value),
            child: Opacity(
              opacity: 0.7 + (0.3 * _animation.value),
              child: _screens[_getScreenIndex(_selectedIndex)],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_icons.length, (index) {
                final isSelected = _selectedIndex == index;
                final isCentralButton = index == 2;

                return GestureDetector(
                  onTap: () => _onItemTapped(index),
                  child: isCentralButton
                      ? _buildCentralButton()
                      : AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: _buildIcon(index, isSelected),
                        ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCentralButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            secondaryColor,
            secondaryColor.withOpacity(0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.add_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildIcon(int index, bool isSelected) {
    if (index == 3) {
      // Carrello con badge (ora è all'indice 3)
      return Consumer<CartProvider>(
        builder: (ctx, cart, ch) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                child: Icon(
                  _icons[index],
                  color: isSelected ? secondaryColor : Colors.grey[600],
                  size: isSelected ? 28 : 24,
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      cart.itemCount > 99 ? '99+' : cart.itemCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: Icon(
        _icons[index],
        color: isSelected ? secondaryColor : Colors.grey[600],
        size: isSelected ? 28 : 24,
      ),
    );
  }
}
