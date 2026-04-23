import 'package:flutter/material.dart';

import 'package:restalltech/Screens/UnloadingGoods/components/unloadingGoods.dart';
import 'package:restalltech/theme.dart';

class UnloadingGoodsScreen extends StatelessWidget {
  static String routeName = "unloading_goods";

  const UnloadingGoodsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Reso',
        debugShowCheckedModeBanner: false,
        theme: theme(),
        home: const UnloadingGoods());
  }
}
