import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/models/Product.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        //set border radius more than 50% of height and width to make circle
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image(
            image: AssetImage(product.images[0]),
            fit: BoxFit.fill,
            height: 100,
          ),
          ListTile(
            title: Text(
              product.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              product.description,
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
          ),
          Column(
            children: <Widget>[
              ListTile(
                  title: Text(
                "\€${product.price}",
                style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
              )),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Container(
                      height: 30.0,
                      width: 30.0,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Material(
                        color: secondaryColor.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: InkWell(
                          onTap: () {},
                          child: const Center(
                            child: Icon(
                              Icons.shopping_cart_rounded,
                              size: 15.0,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      height: 30.0,
                      width: 30.0,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Material(
                        color: secondaryColor.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: InkWell(
                          onTap: () {},
                          child: const Center(
                            child: Icon(
                              Icons.favorite_outline_outlined,
                              size: 15.0,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(height: 50),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
