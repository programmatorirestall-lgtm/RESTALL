import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Order {
  final int id;
  final int parentId;
  final String number;
  final String status;
  final String currency;
  final String dateCreated;
  final String dateModified;
  final String total;
  final String customerNote;
  final Billing billing;
  final Shipping shipping;
  final String paymentMethod;
  final String paymentMethodTitle;
  final List<LineItem> lineItems;
  final List<ShippingLine> shippingLines;
  final List<MetaData> metaData;

  Order({
    required this.id,
    required this.parentId,
    required this.number,
    required this.status,
    required this.currency,
    required this.dateCreated,
    required this.dateModified,
    required this.total,
    required this.customerNote,
    required this.billing,
    required this.shipping,
    required this.paymentMethod,
    required this.paymentMethodTitle,
    required this.lineItems,
    required this.shippingLines,
    required this.metaData,
  });

  // Getters formattati
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(dateCreated);
      return DateFormat('dd/MM/yyyy - HH:mm', 'it_IT').format(dateTime);
    } catch (e) {
      return dateCreated;
    }
  }

  String get formattedTotal {
    try {
      final amount = double.parse(total);
      return NumberFormat.currency(locale: 'it_IT', symbol: '€').format(amount);
    } catch (e) {
      return '€$total';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.orange[600]!;
      case 'completed':
        return Colors.green[600]!;
      case 'on-hold':
        return Colors.amber[600]!;
      case 'pending':
        return Colors.blue[600]!;
      case 'cancelled':
        return Colors.grey[500]!;
      case 'refunded':
        return Colors.purple[400]!;
      case 'failed':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'In Lavorazione';
      case 'completed':
        return 'Completato';
      case 'on-hold':
        return 'In Attesa';
      case 'pending':
        return 'In Attesa di Pagamento';
      case 'cancelled':
        return 'Annullato';
      case 'refunded':
        return 'Rimborsato';
      case 'failed':
        return 'Fallito';
      default:
        return status.toUpperCase();
    }
  }

  int get totalItems {
    return lineItems.fold(0, (sum, item) => sum + item.quantity);
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      parentId: json['parent_id'] ?? 0,
      number: json['number']?.toString() ?? '',
      status: json['status'] ?? 'unknown',
      currency: json['currency'] ?? 'EUR',
      dateCreated: json['date_created'] ?? '',
      dateModified: json['date_modified'] ?? '',
      total: json['total']?.toString() ?? '0.00',
      customerNote: json['customer_note'] ?? '',
      billing: Billing.fromJson(json['billing'] ?? {}),
      shipping: Shipping.fromJson(json['shipping'] ?? {}),
      paymentMethod: json['payment_method'] ?? '',
      paymentMethodTitle: json['payment_method_title'] ?? '',
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((item) => LineItem.fromJson(item))
              .toList() ??
          [],
      shippingLines: (json['shipping_lines'] as List<dynamic>?)
              ?.map((item) => ShippingLine.fromJson(item))
              .toList() ??
          [],
      metaData: (json['meta_data'] as List<dynamic>?)
              ?.map((item) => MetaData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class Billing {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String email;
  final String phone;

  Billing({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.email,
    required this.phone,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get fullAddress {
    final parts = <String>[];
    if (address1.isNotEmpty) parts.add(address1);
    if (address2.isNotEmpty) parts.add(address2);
    if (postcode.isNotEmpty && city.isNotEmpty) {
      parts.add('$postcode $city');
    }
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class Shipping {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;

  Shipping({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Shipping.fromJson(Map<String, dynamic> json) {
    return Shipping(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class LineItem {
  final int id;
  final String name;
  final int productId;
  final int variationId;
  final int quantity;
  final String total;
  final String sku;
  final double price;
  final OrderImage? image;

  LineItem({
    required this.id,
    required this.name,
    required this.productId,
    required this.variationId,
    required this.quantity,
    required this.total,
    required this.sku,
    required this.price,
    this.image,
  });

  String get formattedPrice {
    return NumberFormat.currency(locale: 'it_IT', symbol: '€').format(price);
  }

  String get formattedTotal {
    try {
      final amount = double.parse(total);
      return NumberFormat.currency(locale: 'it_IT', symbol: '€').format(amount);
    } catch (e) {
      return '€$total';
    }
  }

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productId: json['product_id'] ?? 0,
      variationId: json['variation_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      total: json['total']?.toString() ?? '0.00',
      sku: json['sku'] ?? '',
      price: (json['price'] is String)
          ? double.tryParse(json['price']) ?? 0.0
          : json['price']?.toDouble() ?? 0.0,
      image: json['image'] != null ? OrderImage.fromJson(json['image']) : null,
    );
  }
}

class OrderImage {
  final String id;
  final String src;

  OrderImage({required this.id, required this.src});

  factory OrderImage.fromJson(Map<String, dynamic> json) {
    return OrderImage(
      id: json['id']?.toString() ?? '',
      src: json['src'] ?? '',
    );
  }
}

class ShippingLine {
  final int id;
  final String methodTitle;
  final String total;

  ShippingLine({
    required this.id,
    required this.methodTitle,
    required this.total,
  });

  factory ShippingLine.fromJson(Map<String, dynamic> json) {
    return ShippingLine(
      id: json['id'] ?? 0,
      methodTitle: json['method_title'] ?? '',
      total: json['total']?.toString() ?? '0.00',
    );
  }
}

class MetaData {
  final int id;
  final String key;
  final String value;

  MetaData({
    required this.id,
    required this.key,
    required this.value,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}
