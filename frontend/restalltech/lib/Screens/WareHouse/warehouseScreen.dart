import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restalltech/Screens/WareHouse/components/warehouse.dart';
import 'package:restalltech/Screens/WareHouse/components/warehouseProvider.dart';
import 'package:restalltech/theme.dart';

class WareHouseScreen extends StatelessWidget {
  const WareHouseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WarehouseProvider(),
      child: MaterialApp(
        home: const WareHouse(),
        theme: theme(),
      ),
    );
  }
}
