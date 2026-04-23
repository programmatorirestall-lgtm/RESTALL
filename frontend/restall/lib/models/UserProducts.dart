class UserProductsResponse {
  final List<ProductBase> draft;
  final List<ProductBase> published;
  final List<SoldProduct> sold;

  UserProductsResponse({
    required this.draft,
    required this.published,
    required this.sold,
  });

  factory UserProductsResponse.fromJson(Map<String, dynamic> json) {
    return UserProductsResponse(
      draft: (json['draft'] as List<dynamic>?)
              ?.map((item) => ProductBase.fromJson(item))
              .toList() ??
          [],
      published: (json['published'] as List<dynamic>?)
              ?.map((item) => ProductBase.fromJson(item))
              .toList() ??
          [],
      sold: (json['sold'] as List<dynamic>?)
              ?.map((item) => SoldProduct.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ProductBase {
  final int id;
  final String name;
  final String price;
  final String status;
  final List<ProductImageBase> images;
  final int? stockQuantity;

  ProductBase({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    required this.images,
    this.stockQuantity,
  });

  factory ProductBase.fromJson(Map<String, dynamic> json) {
    // Parse price more robustly to handle various formats
    String parsedPrice = '0.00';
    try {
      final priceValue = json['price'];
      if (priceValue != null && priceValue.toString().isNotEmpty) {
        // Try to parse as number and format with 2 decimal places
        final numPrice = double.tryParse(priceValue.toString());
        if (numPrice != null) {
          parsedPrice = numPrice.toStringAsFixed(2);
        }
      }
    } catch (e) {
      // Default to 0.00 on any parsing error
      parsedPrice = '0.00';
    }

    return ProductBase(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: parsedPrice,
      status: json['status'] ?? 'draft',
      images: (json['images'] as List<dynamic>?)
              ?.map((img) => ProductImageBase.fromJson(img))
              .toList() ??
          [],
      stockQuantity: json['stock_quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'status': status,
      'images': images.map((img) => img.toJson()).toList(),
      'stock_quantity': stockQuantity,
    };
  }
}

class ProductImageBase {
  final int id;
  final String src;
  final String? alt;

  ProductImageBase({
    required this.id,
    required this.src,
    this.alt,
  });

  factory ProductImageBase.fromJson(Map<String, dynamic> json) {
    return ProductImageBase(
      id: json['id'] ?? 0,
      src: json['src'] ?? '',
      alt: json['alt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'src': src,
      'alt': alt,
    };
  }
}

class SoldProduct extends ProductBase {
  final int totalSold;
  final List<OrderSummary> orders;

  SoldProduct({
    required int id,
    required String name,
    required String price,
    required String status,
    required List<ProductImageBase> images,
    int? stockQuantity,
    required this.totalSold,
    required this.orders,
  }) : super(
          id: id,
          name: name,
          price: price,
          status: status,
          images: images,
          stockQuantity: stockQuantity,
        );

  factory SoldProduct.fromJson(Map<String, dynamic> json) {
    // Parse price more robustly to handle various formats
    String parsedPrice = '0.00';
    try {
      final priceValue = json['price'];
      if (priceValue != null && priceValue.toString().isNotEmpty) {
        // Try to parse as number and format with 2 decimal places
        final numPrice = double.tryParse(priceValue.toString());
        if (numPrice != null) {
          parsedPrice = numPrice.toStringAsFixed(2);
        }
      }
    } catch (e) {
      // Default to 0.00 on any parsing error
      parsedPrice = '0.00';
    }

    return SoldProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: parsedPrice,
      status: json['status'] ?? 'publish',
      images: (json['images'] as List<dynamic>?)
              ?.map((img) => ProductImageBase.fromJson(img))
              .toList() ??
          [],
      stockQuantity: json['stock_quantity'],
      totalSold: json['total_sold'] ?? 0,
      orders: (json['orders'] as List<dynamic>?)
              ?.map((order) => OrderSummary.fromJson(order))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['total_sold'] = totalSold;
    json['orders'] = orders.map((order) => order.toJson()).toList();
    return json;
  }
}

class OrderSummary {
  final int orderId;
  final String date;
  final String status;
  final int quantity;
  final String total;
  final CustomerInfo customer;

  OrderSummary({
    required this.orderId,
    required this.date,
    required this.status,
    required this.quantity,
    required this.total,
    required this.customer,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    // Parse total price more robustly
    String parsedTotal = '0.00';
    try {
      final totalValue = json['total'];
      if (totalValue != null && totalValue.toString().isNotEmpty) {
        final numTotal = double.tryParse(totalValue.toString());
        if (numTotal != null) {
          parsedTotal = numTotal.toStringAsFixed(2);
        }
      }
    } catch (e) {
      parsedTotal = '0.00';
    }

    return OrderSummary(
      orderId: json['order_id'] ?? 0,
      date: json['date'] ?? '',
      status: json['status'] ?? 'processing',
      quantity: json['quantity'] ?? 0,
      total: parsedTotal,
      customer: CustomerInfo.fromJson(json['customer'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'date': date,
      'status': status,
      'quantity': quantity,
      'total': total,
      'customer': customer.toJson(),
    };
  }
}

class CustomerInfo {
  final String name;
  final String email;

  CustomerInfo({
    required this.name,
    required this.email,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
    };
  }
}
