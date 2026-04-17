// CartItemCard - Card per un singolo item del carrello con operazioni asincrone
import 'package:flutter/material.dart';
import 'package:restall/models/cart_item.dart';

class CartItemCard extends StatefulWidget {
  final CartItem cartItem;
  final Future<void> Function() onRemove;
  final Future<void> Function() onIncrease;
  final Future<void> Function() onDecrease;

  const CartItemCard({
    Key? key,
    required this.cartItem,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  }) : super(key: key);

  @override
  _CartItemCardState createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  bool _isUpdating = false;

  Future<void> _handleOperation(Future<void> Function() operation) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await operation();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'operazione: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.cartItem.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cartItem.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '€${widget.cartItem.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Subtotale: €${(widget.cartItem.price * widget.cartItem.quantity).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _isUpdating
                          ? null
                          : () => _handleOperation(widget.onDecrease),
                      icon: _isUpdating
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.remove),
                      iconSize: 20,
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.cartItem.quantity.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _isUpdating
                          ? null
                          : () => _handleOperation(widget.onIncrease),
                      icon: _isUpdating
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.add),
                      iconSize: 20,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _isUpdating
                      ? null
                      : () => _handleOperation(widget.onRemove),
                  child: Text(
                    _isUpdating ? 'Rimozione...' : 'Rimuovi',
                    style: TextStyle(
                      color: _isUpdating ? Colors.grey : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
