import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final String slug;
  final String permalink;
  final String sku;
  final double regularPrice;
  final double salePrice;
  int quantities;
  final bool onSale;
  final int totalSales;
  final bool virtual;
  final bool downloadable;
  final String stockStatus;
  final bool reviewsAllowed;
  final int ratingCount;
  final List<Category> categories;
  final List<Tag> tags;
  final List<Attribute> attributes;
  final List<int> variations;
  final List<int> relatedIds;
  final List<ProductImage> images;
  final List<Color> colors;
  final double rating;
  final double price;
  final bool isFavourite;
  final bool isPopular;

  final String dateCreated;
  final String dateCreatedGmt;
  final String dateModified;
  final String dateModifiedGmt;
  final String type;
  final String status;
  final bool featured;
  final String catalogVisibility;
  final String shortDescription;
  final bool purchasable;
  final bool manageStock;
  final int stockQuantity;
  final String backorders;
  final bool backordersAllowed;
  final bool backordered;
  final int lowStockAmount;
  final bool soldIndividually;
  final String weight;
  final Map<String, dynamic> dimensions;
  final bool shippingRequired;
  final bool shippingTaxable;
  final String shippingClass;
  final int shippingClassId;
  final List<int> upsellIds;
  final List<int> crossSellIds;
  final int parentId;
  final String purchaseNote;
  final String priceHtml;
  final bool hasOptions;
  final int menuOrder;
  final String postPassword;
  final bool jetpackSharingEnabled;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.slug,
    required this.permalink,
    required this.sku,
    required this.quantities,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.totalSales,
    required this.virtual,
    required this.downloadable,
    required this.stockStatus,
    required this.reviewsAllowed,
    required this.ratingCount,
    required this.categories,
    required this.tags,
    required this.attributes,
    required this.variations,
    required this.relatedIds,
    required this.images,
    required this.colors,
    required this.rating,
    required this.price,
    this.isFavourite = false,
    this.isPopular = false,
    required this.dateCreated,
    required this.dateCreatedGmt,
    required this.dateModified,
    required this.dateModifiedGmt,
    required this.type,
    required this.status,
    required this.featured,
    required this.catalogVisibility,
    required this.shortDescription,
    required this.purchasable,
    required this.manageStock,
    required this.stockQuantity,
    required this.backorders,
    required this.backordersAllowed,
    required this.backordered,
    required this.lowStockAmount,
    required this.soldIndividually,
    required this.weight,
    required this.dimensions,
    required this.shippingRequired,
    required this.shippingTaxable,
    required this.shippingClass,
    required this.shippingClassId,
    required this.upsellIds,
    required this.crossSellIds,
    required this.parentId,
    required this.purchaseNote,
    required this.priceHtml,
    required this.hasOptions,
    required this.menuOrder,
    required this.postPassword,
    required this.jetpackSharingEnabled,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var f = NumberFormat("###.0#", "it_IT");
    var list = json['images'] as List;
    List<ProductImage> imagesList =
        list.map((i) => ProductImage.fromJson(i)).toList();

    var categoriesList = json['categories'] != null
        ? List.from(json['categories'])
            .map((c) => Category.fromJson(c))
            .toList()
        : <Category>[];

    var tagsList = json['tags'] != null
        ? List.from(json['tags']).map((t) => Tag.fromJson(t)).toList()
        : <Tag>[];

    var attributesList = json['attributes'] != null
        ? List.from(json['attributes'])
            .map((a) => Attribute.fromJson(a))
            .toList()
        : <Attribute>[];

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      slug: json['slug'] ?? '',
      permalink: json['permalink'] ?? '',
      sku: json['sku'] ?? '',
      regularPrice:
          double.tryParse(json['regular_price']?.toString() ?? '') ?? 0.0,
      salePrice: double.tryParse(json['sale_price']?.toString() ?? '') ?? 0.0,
      onSale: json['onSale'] ?? false,
      totalSales: int.tryParse(json['total_sales']?.toString() ?? '') ?? 0,
      virtual: json['virtual'] ?? false,
      downloadable: json['downloadable'] ?? false,
      stockStatus: json['stockStatus'] ?? '',
      reviewsAllowed: json['reviewsAllowed'] ?? false,
      ratingCount: int.tryParse(json['rating_count']?.toString() ?? '') ?? 0,
      quantities: 1,
      categories: categoriesList,
      tags: tagsList,
      attributes: attributesList,
      variations: json['variations'] != null
          ? List<int>.from(json['variations'])
          : <int>[],
      relatedIds: json['relatedIds'] != null
          ? List<int>.from(json['relatedIds'])
          : <int>[],
      images: imagesList,
      colors: [], // Add colors list if available
      rating: double.tryParse(json['average_rating']?.toString() ?? '') ?? 0.0,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      isFavourite:
          json['isFavourite'] ?? false, // Handle favorite status if available
      isPopular:
          json['isPopular'] ?? false, // Handle popular status if available

      dateCreated: json['dateCreated'] ?? '',
      dateCreatedGmt: json['dateCreatedGmt'] ?? '',
      dateModified: json['dateModified'] ?? '',
      dateModifiedGmt: json['dateModifiedGmt'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      featured: json['featured'] ?? false,
      catalogVisibility: json['catalogVisibility'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      purchasable: json['purchasable'] ?? false,
      manageStock: json['manageStock'] ?? false,
      stockQuantity: json['stock_quantity'] != null
          ? (json['stock_quantity'] is int
              ? json['stock_quantity']
              : int.tryParse(json['stock_quantity'].toString()))
          : 0,
      backorders: json['backorders'] ?? '',
      backordersAllowed: json['backordersAllowed'] ?? false,
      backordered: json['backordered'] ?? false,
      lowStockAmount: json['lowStockAmount'] ?? 0,
      soldIndividually: json['soldIndividually'] ?? false,
      weight: json['weight'] ?? '',
      dimensions: json['dimensions'] != null && json['dimensions'] is Map
          ? Map<String, dynamic>.from(json['dimensions'])
          : <String, dynamic>{},
      shippingRequired: json['shippingRequired'] ?? false,
      shippingTaxable: json['shippingTaxable'] ?? false,
      shippingClass: json['shippingClass'] ?? '',
      shippingClassId: json['shippingClassId'] ?? 0,
      upsellIds: json['upsellIds'] != null
          ? List<int>.from(json['upsellIds'])
          : <int>[],
      crossSellIds: json['crossSellIds'] != null
          ? List<int>.from(json['crossSellIds'])
          : <int>[],
      parentId: json['parentId'] ?? 0,
      purchaseNote: json['purchaseNote'] ?? '',
      priceHtml: json['priceHtml'] ?? '',
      hasOptions: json['hasOptions'] ?? false,
      menuOrder: json['menuOrder'] ?? 0,
      postPassword: json['postPassword'] ?? '',
      jetpackSharingEnabled: json['jetpackSharingEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'slug': slug,
      'permalink': permalink,
      'sku': sku,
      'regular_price': regularPrice.toString(),
      'sale_price': salePrice.toString(),
      'quantities': quantities,
      'on_sale': onSale,
      'total_sales': totalSales,
      'virtual': virtual,
      'downloadable': downloadable,
      'stock_status': stockStatus,
      'reviews_allowed': reviewsAllowed,
      'rating_count': ratingCount,
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'tags': tags.map((tag) => tag.toJson()).toList(),
      'attributes': attributes.map((attr) => attr.toJson()).toList(),
      'variations': variations,
      'related_ids': relatedIds,
      'images': images.map((img) => img.toJson()).toList(),
      'rating': rating,
      'price': price,
      'is_favourite': isFavourite,
      'is_popular': isPopular,
      'date_created': dateCreated,
      'date_created_gmt': dateCreatedGmt,
      'date_modified': dateModified,
      'date_modified_gmt': dateModifiedGmt,
      'type': type,
      'status': status,
      'featured': featured,
      'catalog_visibility': catalogVisibility,
      'short_description': shortDescription,
      'purchasable': purchasable,
      'manage_stock': manageStock,
      'stock_quantity': stockQuantity,
      'backorders': backorders,
      'backorders_allowed': backordersAllowed,
      'backordered': backordered,
      'low_stock_amount': lowStockAmount,
      'sold_individually': soldIndividually,
      'weight': weight,
      'dimensions': dimensions,
      'shipping_required': shippingRequired,
      'shipping_taxable': shippingTaxable,
      'shipping_class': shippingClass,
      'shipping_class_id': shippingClassId,
      'upsell_ids': upsellIds,
      'cross_sell_ids': crossSellIds,
      'parent_id': parentId,
      'purchase_note': purchaseNote,
      'price_html': priceHtml,
      'has_options': hasOptions,
      'menu_order': menuOrder,
      'post_password': postPassword,
      'jetpack_sharing_enabled': jetpackSharingEnabled,
    };
  }
}

class ProductImage {
  final int id;
  final String dateCreated;
  final String dateCreatedGmt;
  final String dateModified;
  final String dateModifiedGmt;
  final String src;
  final String name;
  final String alt;

  ProductImage({
    required this.id,
    required this.dateCreated,
    required this.dateCreatedGmt,
    required this.dateModified,
    required this.dateModifiedGmt,
    required this.src,
    required this.name,
    required this.alt,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateCreated': dateCreated,
      'dateCreatedGmt': dateCreatedGmt,
      'dateModified': dateModified,
      'dateModifiedGmt': dateModifiedGmt,
      'src': src,
      'name': name,
      'alt': alt,
    };
  }

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      dateCreated: json['dateCreated'] ?? '',
      dateCreatedGmt: json['dateCreatedGmt'] ?? '',
      dateModified: json['dateModified'] ?? '',
      dateModifiedGmt: json['dateModifiedGmt'] ?? '',
      src: json['src'] ?? '',
      name: json['name'] ?? '',
      alt: json['alt'] ?? '',
    );
  }
}

class Category {
  final int id;
  final String name;
  final String slug;

  Category({
    required this.id,
    required this.name,
    required this.slug,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class Tag {
  final int id;
  final String name;
  final String slug;

  Tag({
    required this.id,
    required this.name,
    required this.slug,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class Attribute {
  final int id;
  final String name;
  final int position;
  final bool visible;
  final bool variation;
  final List<String> options;

  Attribute({
    required this.id,
    required this.name,
    required this.position,
    required this.visible,
    required this.variation,
    required this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'visible': visible,
      'variation': variation,
      'options': options,
    };
  }

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      position: json['position'] ?? 0,
      visible: json['visible'] ?? false,
      variation: json['variation'] ?? false,
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : <String>[],
    );
  }
}
