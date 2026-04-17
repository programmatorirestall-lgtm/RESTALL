import 'package:flutter/material.dart';

import 'package:restalltech/Screens/LoadingGoods/components/loadingGoods.dart';
import 'package:restalltech/Screens/PriceProduct/components/priceProduct.dart';
import 'package:restalltech/theme.dart';

class PriceProductScreen extends StatelessWidget {
  static String routeName = "/price_product";

  const PriceProductScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Prezzo',
        debugShowCheckedModeBanner: false,
        theme: theme(),
        home: const PriceProduct());
  }
}
