import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/Screens/WishListScreen/wishListScreen.dart';
import 'package:restall/Screens/orders/orders_screen.dart';
import 'package:restall/Screens/seller_dashboard/seller_dashboard_screen.dart';
import 'package:restall/Screens/my_products/my_products_screen.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/Profile/profile_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              secondaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header con titolo
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Il Mio Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              _buildSectionCard(
              context: context,
              title: 'I Miei Ordini',
              subtitle: 'Visualizza lo stato dei tuoi ordini',
              icon: Icons.receipt_long_rounded,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrdersScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context: context,
              title: 'Wishlist',
              subtitle: 'I tuoi prodotti preferiti',
              icon: Icons.favorite_rounded,
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WishlistScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                // Mostra la card solo se l'utente è un venditore verificato
                if (!profileProvider.isSellerVerified) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    _buildSectionCard(
                      context: context,
                      title: 'Prodotti in Vendita',
                      subtitle: 'Gestisci i tuoi prodotti',
                      icon: Icons.storefront_rounded,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyProductsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                // Mostra la card solo se l'utente è un venditore verificato
                if (!profileProvider.isSellerVerified) {
                  return const SizedBox.shrink();
                }

                return _buildSectionCard(
                  context: context,
                  title: 'Portafoglio',
                  subtitle: 'Visualizza i tuoi guadagni',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SellerDashboardScreen()),
                    );
                  },
                );
              },
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
