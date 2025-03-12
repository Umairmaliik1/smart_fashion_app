import 'package:flutter/foundation.dart';

class CartModel extends ChangeNotifier {
  // List of items added to the cart.
  // For simplicity, each item is represented as a Map.
  final List<Map<String, String>> _items = [];

  List<Map<String, String>> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  void addItem(Map<String, String> item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(Map<String, String> item) {
    _items.remove(item);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
