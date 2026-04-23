import 'package:flutter/material.dart';

import 'package:restalltech/Screens/LoadingGoods/components/loadingGoods.dart';
import 'package:restalltech/theme.dart';

class LoadingGoodsScreen extends StatelessWidget {
  static String routeName = "/loading_goods";

  const LoadingGoodsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Prelievo',
        debugShowCheckedModeBanner: false,
        theme: theme(),
        home: const LoadingGoods());
  }
}
