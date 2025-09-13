import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      debugPrint('DateTime parse error: $e for value: $value');
      return DateTime.now();
    }
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  debugPrint('Unknown date format: $value');
  return DateTime.now();
}

int parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

double parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

final _nairaFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦');

class BargainItem {
  final String productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final String? imageUrl;
  
  

  BargainItem({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    this.imageUrl,
  });

  factory BargainItem.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing BargainItem: $json');

    final productData = json['product'];
    String productId = '';
    String productName = 'Unnamed Product';
    double productPrice = 0.0;
    String? imageUrl;

    if (productData is Map<String, dynamic>) {
      productId = productData['_id']?.toString() ?? '';
      productName = productData['name'] ?? 'Unnamed Product';
      productPrice = parseDouble(productData['price']);

      String? rawImage = productData['imageUrl'] ?? productData['images']?[0];

      // Handle image URL: add base URL if not absolute
      imageUrl = (rawImage != null && !rawImage.startsWith('http'))
          ? 'http://172.20.10.2:5000/${rawImage.startsWith('/') ? rawImage.substring(1) : rawImage}'
          : rawImage;

      debugPrint('🖼️ Final image URL: $imageUrl');
    } else if (productData is String) {
      productId = productData;
      productPrice = parseDouble(json['price']);
      // productName stays default
    }

    return BargainItem(
      productId: productId,
      productName: productName,
      productPrice: productPrice,
      quantity: parseInt(json['quantity']),
      imageUrl: imageUrl,
    );
  }

  String get displayPrice => _nairaFormat.format(productPrice);

  /// Converts the object to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'price': productPrice,
      'imageUrl': imageUrl,
    };
  }
}



class BuyerOffer {
  final List<BargainItem> items;
  final double totalOfferedPrice;
  final DateTime time;
  final String buyerName;
  final String buyerPhone;
  final String? note;  // ✅ Add this line

  BuyerOffer({
    required this.items,
    required this.totalOfferedPrice,
    required this.time,
    required this.buyerName,
    required this.buyerPhone,
    this.note, // ✅ Add to constructor
  });

  double get totalPrice => totalOfferedPrice;
  String get displayTotal => _nairaFormat.format(totalOfferedPrice);

  factory BuyerOffer.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing BuyerOffer: $json');

    var itemsJson = json['items'] as List<dynamic>? ?? [];
    List<BargainItem> itemsList =
        itemsJson.map((e) => BargainItem.fromJson(e)).toList();

    return BuyerOffer(
      items: itemsList,
      totalOfferedPrice: parseDouble(json['totalOfferedPrice']),
      time: _parseDate(json['time']),
      buyerName: json['buyerName'] ?? '',
      buyerPhone: json['buyerPhone'] ?? '',
      note: json['note'], // ✅ Pull from backend JSON if present
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'totalOfferedPrice': totalOfferedPrice,
      'time': time.toIso8601String(),
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'note': note, // ✅ Include in output JSON
    };
  }
}

class SellerOffer {
  final List<BargainItem> items;
  final double totalCounterPrice;
  final DateTime time;

  SellerOffer({
    required this.items,
    required this.totalCounterPrice,
    required this.time,
  });

  double get totalPrice => totalCounterPrice;
  String get displayTotal => _nairaFormat.format(totalCounterPrice);

  factory SellerOffer.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing SellerOffer: $json');

    var itemsJson = json['items'] as List<dynamic>? ?? [];
    List<BargainItem> itemsList =
        itemsJson.map((e) => BargainItem.fromJson(e)).toList();

    return SellerOffer(
      items: itemsList,
      totalCounterPrice: parseDouble(json['totalCounterPrice']),
      time: _parseDate(json['time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'totalCounterPrice': totalCounterPrice,
      'time': time.toIso8601String(),
    };
  }
}

class Bargain {
  final String id;
  final String sellerId;
  final String sellerName;
  final List<BuyerOffer> buyerOffers;
  final List<SellerOffer> sellerOffers;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? acceptedPrice;
  final List<String> productIds;
  final String lastOfferBy;
  bool addedToCart;
  final String buyerPhone;
  final String? acceptedFrom;

  Bargain({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.buyerOffers,
    required this.sellerOffers,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedPrice,
    required this.productIds,
    required this.lastOfferBy,
    this.addedToCart = false,
    required this.buyerPhone, 
    this.acceptedFrom, 
  });

  double? get acceptedOfferPrice {
    if (status.toLowerCase() != 'accepted') return null;

    if (lastOfferBy.toLowerCase() == 'seller') {
      if (sellerOffers.isNotEmpty) {
        final lastSellerPrice = sellerOffers.last.totalCounterPrice;
        if (lastSellerPrice > 0) return lastSellerPrice;
      }
    } else if (lastOfferBy.toLowerCase() == 'buyer') {
      if (buyerOffers.isNotEmpty) {
        final lastBuyerPrice = buyerOffers.last.totalOfferedPrice;
        if (lastBuyerPrice > 0) return lastBuyerPrice;
      }
    }

    return acceptedPrice;
  }

  String get displayAcceptedOfferPrice =>
      acceptedOfferPrice != null ? _nairaFormat.format(acceptedOfferPrice!) : 'N/A';

 factory Bargain.fromJson(Map<String, dynamic> json) {
  debugPrint('Parsing Bargain: $json');

  var buyerOffersJson = json['buyerOffers'] as List<dynamic>? ?? [];
  var sellerOffersJson = json['sellerOffers'] as List<dynamic>? ?? [];

  List<BuyerOffer> buyerOffersList =
      buyerOffersJson.map((e) => BuyerOffer.fromJson(e)).toList();
  List<SellerOffer> sellerOffersList =
      sellerOffersJson.map((e) => SellerOffer.fromJson(e)).toList();

  final sellerField = json['seller'];
  String sellerId = '';
  String sellerName = '';

  if (sellerField is Map<String, dynamic>) {
    sellerId = sellerField['_id']?.toString() ?? '';
    sellerName = sellerField['name'] ?? '';
  } else if (sellerField is String) {
    sellerId = sellerField;
  }

  // ✅ Handle flat successful bargain structure (fallback)
  if (buyerOffersList.isEmpty && sellerOffersList.isEmpty) {
    final flatItem = BargainItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? 'Unnamed',
      productPrice: parseDouble(json['price']),
      quantity: parseInt(json['quantity']),
      imageUrl: json['imageUrl'],
    );

    final lastBy = (json['lastOfferBy'] ?? 'seller').toLowerCase();

    if (lastBy == 'buyer') {
      buyerOffersList.add(BuyerOffer(
        items: [flatItem],
        totalOfferedPrice: flatItem.productPrice * flatItem.quantity,
        time: _parseDate(json['updatedAt']),
        buyerName: json['buyerName'] ?? '',
        buyerPhone: json['buyerPhone'] ?? '',
      ));
    } else {
      sellerOffersList.add(SellerOffer(
        items: [flatItem],
        totalCounterPrice: flatItem.productPrice * flatItem.quantity,
        time: _parseDate(json['updatedAt']),
      ));
    }
  }

  return Bargain(
    id: json['_id']?.toString() ?? json['bargainId'] ?? '',
    sellerId: sellerId.isNotEmpty ? sellerId : json['sellerId'] ?? '',
    sellerName: sellerName,
    buyerOffers: buyerOffersList,
    sellerOffers: sellerOffersList,
    status: json['status'] ?? 'accepted',
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
    acceptedPrice: json['acceptedPrice'] != null
        ? parseDouble(json['acceptedPrice'])
        : parseDouble(json['price']),
    productIds: List<String>.from(json['productIds'] ?? (json['productId'] != null ? [json['productId']] : [])),
    lastOfferBy: json['lastOfferBy'] ?? 'seller',
    addedToCart: json['addedToCart'] ?? false,
    buyerPhone: json['buyerPhone'] ?? '',
    acceptedFrom: json['acceptedFrom'],
  );
}


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'seller': {
        '_id': sellerId,
        'name': sellerName,
      },
      'buyerOffers': buyerOffers.map((e) => e.toJson()).toList(),
      'sellerOffers': sellerOffers.map((e) => e.toJson()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'acceptedPrice': acceptedPrice,
      'productIds': productIds,
      'lastOfferBy': lastOfferBy,
      'addedToCart': addedToCart,
      'buyerPhone': buyerPhone,
      'acceptedFrom': acceptedFrom,
    };
  }
}
