import 'package:flutter/foundation.dart';

class MySensitiveDataProvider extends ChangeNotifier {
  late String _sensitiveData;

  String get sensitiveData => _sensitiveData;

  void setSensitiveData(String newData) {
    _sensitiveData = newData;
    notifyListeners();
  }
}
