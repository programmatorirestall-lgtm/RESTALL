import 'package:flutter/material.dart';
import 'package:restall/API/Cart/cart.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/Cart.dart';

class CartCard extends StatefulWidget {
  final Cart cart;
  const CartCard({Key? key, required this.cart}) : super(key: key);

  @override
  State<CartCard> createState() => _CartCardState();
}

class _CartCardState extends State<CartCard> {
  Future<void> _updateCart(Function updateLogic) async {
    updateLogic();

    await CartApi().addCart({
      'cart': {
        'items': demoCarts
            .map((item) => {
                  'idProdotto': item.idProdotto,
                  'quantita': item.numOfItem,
                  'prezzo': item.prezzo
                })
            .toList()
      }
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: AspectRatio(
            aspectRatio: 0.88,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.network(
                widget.cart.product.images.isNotEmpty
                    ? widget.cart.product.images[0].src
                    : 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cart.product.name.isNotEmpty
                  ? widget.cart.product.name
                  : 'Prodotto #${widget.cart.idProdotto}',
              style: const TextStyle(color: Colors.black, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: "€${widget.cart.product.price}",
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: kPrimaryColor),
                children: [
                  TextSpan(
                      text: " x${widget.cart.numOfItem}",
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    final index = demoCarts.indexWhere(
                        (item) => item.idProdotto == widget.cart.idProdotto);
                    if (index != -1) {
                      await _updateCart(() {
                        demoCarts[index].numOfItem++;
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: kPrimaryColor,
                ),
                IconButton(
                  onPressed: () async {
                    final index = demoCarts.indexWhere(
                        (item) => item.idProdotto == widget.cart.idProdotto);
                    if (index != -1) {
                      await _updateCart(() {
                        if (demoCarts[index].numOfItem > 1) {
                          demoCarts[index].numOfItem--;
                        } else {
                          demoCarts.removeAt(index);
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: kPrimaryColor,
                ),
              ],
            )
          ],
        ),
      ],
    );
  }
}
