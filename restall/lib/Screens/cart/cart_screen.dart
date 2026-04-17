import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/Screens/CheckOutScreen/checkout_screen.dart';
import 'package:restall/components/cartItemCard.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/Cart/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Consumer<CartProvider>(
          builder: (ctx, cart, _) {
            if (cart.isLoading && cart.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Caricamento carrello...'),
                  ],
                ),
              );
            }

            if (cart.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
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
                          Icons.shopping_cart_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Il carrello è vuoto!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aggiungi i prodotti al carrello\nper procedere con l\'acquisto!',
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

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => cart.syncCartFromServer(),
                    child: ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (ctx, i) {
                        final cartItem = cart.items.values.toList()[i];
                        return CartItemCard(
                          cartItem: cartItem,
                          onRemove: () => cart.removeItem(cartItem.id),
                          onIncrease: () => cart.addItemFromDetails(
                            productId: cartItem.id,
                            title: cartItem.title,
                            price: cartItem.price,
                            imageUrl: cartItem.imageUrl,
                          ),
                          onDecrease: () => cart.removeSingleItem(cartItem.id),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Totale:',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                            Text(
                              '€${cart.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${cart.itemCount} prodotti nel carrello',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            if (cart.isSyncing)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sincronizzazione...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: cart.items.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CheckOutScreen(),
                                      ),
                                    );
                                  },
                            child: const Text('Procedi al checkout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
