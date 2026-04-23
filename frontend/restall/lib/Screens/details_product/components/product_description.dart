import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../constants.dart';
import '../../../models/Product.dart';

class ProductDescription extends StatelessWidget {
  const ProductDescription({
    Key? key,
    required this.product,
    this.pressOnSeeMore,
  }) : super(key: key);

  final Product product;
  final GestureTapCallback? pressOnSeeMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            product.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: (product.salePrice < product.regularPrice)
              ? Row(
                  children: [
                    Text(
                      "€ ${product.regularPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "€ ${product.salePrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                )
              : Text(
                  "€ ${product.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
        ),
        // Align(
        //   alignment: Alignment.centerRight,
        //   child: Container(
        //     padding: const EdgeInsets.all(16),
        //     width: 48,
        //     decoration: BoxDecoration(
        //       color: product.isFavourite
        //           ? const Color(0xFFFFE6E6)
        //           : const Color(0xFFF5F6F9),
        //       borderRadius: const BorderRadius.only(
        //         topLeft: Radius.circular(20),
        //         bottomLeft: Radius.circular(20),
        //       ),
        //     ),
        //     child: SvgPicture.asset(
        //       "assets/icons/Heart Icon_2.svg",
        //       colorFilter: ColorFilter.mode(
        //           product.isFavourite
        //               ? const Color(0xFFFF4848)
        //               : const Color(0xFFDBDEE4),
        //           BlendMode.srcIn),
        //       height: 16,
        //     ),
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 64,
          ),
          child: Html(
            data: product
                .description, // dove htmlFromApi è una stringa HTML ricevuta
          ),
          // child: Text(

          //   product.description,
          //   maxLines: 3,
          // ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: GestureDetector(
            onTap: () {},
            child: const Row(
              children: [
                Text(
                  "Vedi Dettagli",
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: kPrimaryColor),
                ),
                SizedBox(width: 5),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: kPrimaryColor,
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
