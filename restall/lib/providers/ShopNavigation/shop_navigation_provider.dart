import 'package:flutter/material.dart';

class ShopNavigationProvider with ChangeNotifier {
  String _currentShopSection = 'Shop';

  String get currentShopSection => _currentShopSection;

  void updateShopSection(String section) {
    if (_currentShopSection != section) {
      _currentShopSection = section;
      notifyListeners();
    }
  }

  void resetToShop() {
    updateShopSection('Shop');
  }
}
