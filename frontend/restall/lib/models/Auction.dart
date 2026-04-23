// lib/models/Auction.dart - Versione aggiornata per WooCommerce
class Auction {
  final int id;
  final String name;
  final String slug;
  final String permalink;
  final String type;
  final String status;
  final String description;
  final String shortDescription;
  final List<AuctionImage> images;
  final List<AuctionMetaData> metaData;
  final double price;
  final double regularPrice;
  final double? salePrice;
  final String sku;
  final DateTime dateCreated;
  final DateTime dateModified;
  final List<AuctionCategory> categories;
  final List<AuctionTag> tags;

  // Campi specifici per le aste (estratti da meta_data)
  double get startingBid => _getMetaDouble('_auction_start_price') ?? price;
  double get bidIncrement => _getMetaDouble('_auction_bid_increment') ?? 1.0;
  double get reservedPrice => _getMetaDouble('_auction_reserved_price') ?? 0.0;
  double get buyNowPrice => _getMetaDouble('_buy_now_price') ?? 0.0;
  int get bidCount => _getMetaInt('_auction_bid_count') ?? 0;
  String get itemCondition =>
      _getMetaValue('_auction_item_condition') ?? 'used';
  String get auctionType => _getMetaValue('_auction_type') ?? 'normal';

  // Date dell'asta
  DateTime? get startTime =>
      _parseAuctionDateTime(_getMetaValue('_auction_dates_from'));
  DateTime? get endTime =>
      _parseAuctionDateTime(_getMetaValue('_auction_dates_to'));

  // Stato dell'asta calcolato
  bool get hasEnded => endTime?.isBefore(DateTime.now()) ?? false;
  bool get hasStarted => startTime?.isBefore(DateTime.now()) ?? true;
  bool get isActive => hasStarted && !hasEnded;

  Duration? get timeRemaining {
    if (hasEnded || endTime == null) return null;
    final remaining = endTime!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  // Offerta corrente (per ora usa il prezzo di partenza, da aggiornare con API)
  double get currentBid {
    // Prima prova a ottenere l'offerta corrente dai meta_data
    final currentBidFromMeta = _getMetaDouble('_auction_current_bid');
    if (currentBidFromMeta != null && currentBidFromMeta > 0) {
      return currentBidFromMeta;
    }

    // Fallback al prezzo di partenza se non ci sono offerte
    return startingBid;
  }

  String get currentBidder {
    final bidderFromMeta = _getMetaValue(
        '_auction_current_bider'); // Nota: API usa "bider" non "bidder"
    if (bidderFromMeta != null) {
      return bidderFromMeta.toString();
    }
    return '';
  }

  DateTime? get lastBidTime {
    final lastBidTimeString = _getMetaValue('_auction_last_bid_time');
    if (lastBidTimeString != null) {
      try {
        return DateTime.parse(lastBidTimeString.toString());
      } catch (e) {
        print('Errore parsing last bid time: $e');
        return null;
      }
    }
    return null;
  }

  bool hasNewBidSince(DateTime? since) {
    if (since == null || lastBidTime == null) return false;
    return lastBidTime!.isAfter(since);
  }

  const Auction({
    required this.id,
    required this.name,
    required this.slug,
    required this.permalink,
    required this.type,
    required this.status,
    required this.description,
    required this.shortDescription,
    required this.images,
    required this.metaData,
    required this.price,
    required this.regularPrice,
    this.salePrice,
    required this.sku,
    required this.dateCreated,
    required this.dateModified,
    required this.categories,
    required this.tags,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    var imagesList = json['images'] != null
        ? List.from(json['images'])
            .map((i) => AuctionImage.fromJson(i))
            .toList()
        : <AuctionImage>[];

    var metaDataList = json['meta_data'] != null
        ? List.from(json['meta_data'])
            .map((m) => AuctionMetaData.fromJson(m))
            .toList()
        : <AuctionMetaData>[];

    var categoriesList = json['categories'] != null
        ? List.from(json['categories'])
            .map((c) => AuctionCategory.fromJson(c))
            .toList()
        : <AuctionCategory>[];

    var tagsList = json['tags'] != null
        ? List.from(json['tags']).map((t) => AuctionTag.fromJson(t)).toList()
        : <AuctionTag>[];

    return Auction(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      permalink: json['permalink'] ?? '',
      type: json['type'] ?? 'auction',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      images: imagesList,
      metaData: metaDataList,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      regularPrice:
          double.tryParse(json['regular_price']?.toString() ?? '') ?? 0.0,
      salePrice:
          json['sale_price'] != null && json['sale_price'].toString().isNotEmpty
              ? double.tryParse(json['sale_price'].toString())
              : null,
      sku: json['sku'] ?? '',
      dateCreated: _parseDateTime(json['date_created']) ?? DateTime.now(),
      dateModified: _parseDateTime(json['date_modified']) ?? DateTime.now(),
      categories: categoriesList,
      tags: tagsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'permalink': permalink,
      'type': type,
      'status': status,
      'description': description,
      'short_description': shortDescription,
      'images': images.map((img) => img.toJson()).toList(),
      'meta_data': metaData.map((meta) => meta.toJson()).toList(),
      'price': price.toString(),
      'regular_price': regularPrice.toString(),
      'sale_price': salePrice?.toString(),
      'sku': sku,
      'date_created': dateCreated.toIso8601String(),
      'date_modified': dateModified.toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
    };
  }

  // Helper methods per estrarre valori dai meta_data
  dynamic _getMetaValue(String key) {
    try {
      final meta = metaData.firstWhere((m) => m.key == key);
      return meta.value;
    } catch (e) {
      return null;
    }
  }

  double? _getMetaDouble(String key) {
    final value = _getMetaValue(key);
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  int? _getMetaInt(String key) {
    final value = _getMetaValue(key);
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return null;
    }
  }

  static DateTime? _parseAuctionDateTime(dynamic dateString) {
    if (dateString == null) return null;
    try {
      // Formato WooCommerce: "2025-09-30 00:00"
      final cleanDate = dateString.toString().trim();
      if (cleanDate.isEmpty) return null;

      // Se non ha timezone info, assumiamo UTC
      if (!cleanDate.contains('T') && !cleanDate.contains('Z')) {
        return DateTime.parse('${cleanDate}:00Z');
      }
      return DateTime.parse(cleanDate);
    } catch (e) {
      print('Errore parsing data asta: $e per valore: $dateString');
      return null;
    }
  }

  // Helper per formattare il tempo rimanente
  String formatTimeRemaining() {
    final remaining = timeRemaining;
    if (remaining == null) return 'Terminata';

    if (remaining.inDays > 0) {
      return '${remaining.inDays}g ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m';
    } else {
      return '${remaining.inSeconds}s';
    }
  }

  // Helper per lo stato dell'asta
  String getStatusText() {
    if (!hasStarted) return 'IN PROGRAMMA';
    if (hasEnded) return 'TERMINATA';
    return 'LIVE';
  }

  Auction copyWith({
    int? id,
    String? name,
    String? slug,
    String? permalink,
    String? type,
    String? status,
    String? description,
    String? shortDescription,
    List<AuctionImage>? images,
    List<AuctionMetaData>? metaData,
    double? price,
    double? regularPrice,
    double? salePrice,
    String? sku,
    DateTime? dateCreated,
    DateTime? dateModified,
    List<AuctionCategory>? categories,
    List<AuctionTag>? tags,
  }) {
    return Auction(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      permalink: permalink ?? this.permalink,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      images: images ?? this.images,
      metaData: metaData ?? this.metaData,
      price: price ?? this.price,
      regularPrice: regularPrice ?? this.regularPrice,
      salePrice: salePrice ?? this.salePrice,
      sku: sku ?? this.sku,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
    );
  }
}

// Classi di supporto
class AuctionImage {
  final int id;
  final String src;
  final String alt;
  final String name;
  final DateTime dateCreated;

  const AuctionImage({
    required this.id,
    required this.src,
    required this.alt,
    required this.name,
    required this.dateCreated,
  });

  factory AuctionImage.fromJson(Map<String, dynamic> json) {
    return AuctionImage(
      id: json['id'] ?? 0,
      src: json['src'] ?? '',
      alt: json['alt'] ?? '',
      name: json['name'] ?? '',
      dateCreated:
          DateTime.tryParse(json['date_created'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'src': src,
        'alt': alt,
        'name': name,
        'date_created': dateCreated.toIso8601String(),
      };
}

class AuctionMetaData {
  final int id;
  final String key;
  final dynamic value;

  const AuctionMetaData({
    required this.id,
    required this.key,
    required this.value,
  });

  factory AuctionMetaData.fromJson(Map<String, dynamic> json) {
    return AuctionMetaData(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'value': value,
      };
}

class AuctionCategory {
  final int id;
  final String name;
  final String slug;

  const AuctionCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory AuctionCategory.fromJson(Map<String, dynamic> json) {
    return AuctionCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
      };
}

class AuctionTag {
  final int id;
  final String name;
  final String slug;

  const AuctionTag({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory AuctionTag.fromJson(Map<String, dynamic> json) {
    return AuctionTag(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
      };
}
