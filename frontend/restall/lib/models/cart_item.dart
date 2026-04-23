import 'package:flutter/foundation.dart';

@immutable
class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double price;
  final String imageUrl;
  final bool isMarketplace;

  const CartItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    this.isMarketplace = false,
  });

  /// Crea una copia di questo CartItem ma con i campi forniti sostituiti.
  CartItem copyWith({
    String? id,
    String? title,
    int? quantity,
    double? price,
    String? imageUrl,
    bool? isMarketplace,
  }) {
    return CartItem(
      id: id ?? this.id,
      title: title ?? this.title,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isMarketplace: isMarketplace ?? this.isMarketplace,
    );
  }

  /// Converte l'istanza di CartItem in una mappa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'isMarketplace': isMarketplace,
    };
  }

  /// Crea un'istanza di CartItem da una mappa JSON.
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      title: json['title'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      isMarketplace: json['isMarketplace'] as bool? ?? false,
    );
  }
}
