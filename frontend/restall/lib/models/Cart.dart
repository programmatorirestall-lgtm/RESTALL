import 'Product.dart';

class Cart {
  Product product;
  int numOfItem;
  final int idProdotto;
  final double prezzo;

  Cart({
    required this.product,
    required this.numOfItem,
    required this.idProdotto,
    required this.prezzo,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      product: Product(
        id: json['idProdotto'],
        name: '',
        description: '',
        slug: '',
        permalink: '',
        stockQuantity: 0,
        sku: '',
        regularPrice: json['prezzo'].toDouble(),
        salePrice: json['prezzo'].toDouble(),
        quantities: json['quantita'],
        onSale: false,
        totalSales: 0,
        virtual: false,
        downloadable: false,
        stockStatus: '',
        reviewsAllowed: false,
        ratingCount: 0,
        categories: [],
        tags: [],
        attributes: [],
        variations: [],
        relatedIds: [],
        images: [],
        colors: [],
        rating: 0.0,
        price: json['prezzo'].toDouble(),
        // Required fields added below with placeholder/default values
        dateCreated: DateTime.now().toString(),
        dateCreatedGmt: DateTime.now().toUtc().toString(),
        dateModified: DateTime.now().toString(),
        dateModifiedGmt: DateTime.now().toUtc().toString(),
        type: '',
        status: '',
        featured: false,
        catalogVisibility: '',
        shortDescription: '',
        purchasable: false,
        manageStock: false,
        backorders: '',
        backordersAllowed: false,
        backordered: false,
        lowStockAmount: 0,
        soldIndividually: false,
        weight: '',
        dimensions: {},
        shippingRequired: false,
        shippingTaxable: false,
        shippingClass: '',
        shippingClassId: 0,
        upsellIds: [],
        crossSellIds: [],
        parentId: 0,
        purchaseNote: '',
        priceHtml: '',
        hasOptions: false,
        menuOrder: 0,
        postPassword: '',
        jetpackSharingEnabled: false,
      ),
      numOfItem: json['quantita'],
      idProdotto: json['idProdotto'],
      prezzo: json['prezzo'].toDouble(),
    );
  }
}

// Demo data for our cart

List<Cart> demoCarts = [];
