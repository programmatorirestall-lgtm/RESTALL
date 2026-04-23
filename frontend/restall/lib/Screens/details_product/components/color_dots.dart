import 'package:flutter/material.dart';
import 'package:restall/components/rounded_icon_btn.dart';

import '../../../constants.dart';
import '../../../models/Product.dart';

class ColorDots extends StatefulWidget {
  static String routeName = "/details_product";

  final Product product;

  const ColorDots({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  _ColorDotsState createState() => _ColorDotsState();
}

class _ColorDotsState extends State<ColorDots> {
  int counter = 1;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.product.attributes.length > 0) ...[
                ...List.generate(
                  widget.product.attributes[0].options.length,
                  (index) => Variant(
                    variant: widget.product.attributes[0].options[index],
                    isSelected:
                        index == widget.product.attributes[0].options[index],
                  ),
                ),
              ],
              Text(
                "Quantità: ",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryColor,
                ),
              ),
              Text(
                "$counter",
                style: const TextStyle(
                  fontSize: 18,
                  color: kPrimaryColor,
                ),
              ),
              const Spacer(),
              RoundedIconBtn(
                icon: Icons.remove,
                press: () {
                  if (widget.product.stockQuantity != null &&
                      counter > widget.product.stockQuantity!) {
                    setState(() {
                      counter--;
                      widget.product.quantities = counter;
                    });
                  }
                },
              ),
              const SizedBox(width: 20),
              RoundedIconBtn(
                icon: Icons.add,
                showShadow: true,
                press: () {
                  if (widget.product.stockQuantity != null &&
                      counter < widget.product.stockQuantity!) {
                    setState(() {
                      counter++;
                      widget.product.quantities = counter;
                    });
                  }
                },
              ),
            ],
          ),
          Text("Disponibili: ${widget.product.stockQuantity}"),
        ],
      ),
    );
  }
}

class Variant extends StatelessWidget {
  const Variant({
    Key? key,
    required this.variant,
    this.isSelected = false,
  }) : super(key: key);

  final String variant;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.all(8),
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: isSelected ? kPrimaryColor : Colors.red),
          shape: BoxShape.circle,
        ),
        child: Text(variant));
  }
}
