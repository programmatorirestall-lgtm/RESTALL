import 'package:flutter/material.dart';
import 'package:restalltech/Screens/WareHouse/components/warehouseItem.dart';

class WarehouseProvider with ChangeNotifier {
  final List<WarehouseItem> _items = []; // Lista degli oggetti di magazzino

  List<WarehouseItem> get items => _items;

  void addItem(WarehouseItem item) {
    _items.add(item);
    notifyListeners();
  }

  void updateItem(WarehouseItem updatedItem) {
    int index = _items.indexWhere((item) => item.id == updatedItem.id);
    _items[index] = updatedItem;
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
