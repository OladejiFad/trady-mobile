class ProductInOrder {
  final String productId;
  final String productName;
  final int quantity;
  final int price;
  final bool isBargain;
  final String sellerId;

  ProductInOrder({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.isBargain,
    required this.sellerId,
  });

  factory ProductInOrder.fromJson(Map<String, dynamic> json) {
    return ProductInOrder(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0,
      isBargain: json['isBargain'] ?? false,
      sellerId: json['sellerId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'isBargain': isBargain,
      'sellerId': sellerId,
    };
  }
}

class Order {
  final String id;
  final String orderId;
  final String buyerName;
  final String buyerPhone;
  final String buyerLocation;
  final String deliveryStatus; // shipment status (renamed internally)
  final String satisfactionStatus;
  final String paymentStatus;
  final String colorStatus;
  final List<ProductInOrder> products;

  // Optional/extra backend fields
  final String? orderStatus;
  final String? createdAt;

  Order({
    required this.id,
    required this.orderId,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerLocation,
    required this.deliveryStatus,
    required this.satisfactionStatus,
    required this.paymentStatus,
    required this.colorStatus,
    required this.products,
    this.orderStatus,
    this.createdAt,
  });

  // Alias to match logic
  String get shipmentStatus => deliveryStatus;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      buyerName: json['buyerName'] ?? '',
      buyerPhone: json['buyerPhone'] ?? '',
      buyerLocation: json['buyerLocation'] ?? '',
      deliveryStatus: json['shipmentStatus'] ?? json['deliveryStatus'] ?? '',
      satisfactionStatus: json['satisfactionStatus'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      colorStatus: json['colorStatus'] ?? '',
      products: (json['products'] as List<dynamic>? ?? [])
          .map((productJson) => ProductInOrder.fromJson(productJson))
          .toList(),
      orderStatus: json['orderStatus'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderId': orderId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerLocation': buyerLocation,
      'shipmentStatus': deliveryStatus,
      'satisfactionStatus': satisfactionStatus,
      'paymentStatus': paymentStatus,
      'colorStatus': colorStatus,
      'products': products.map((p) => p.toJson()).toList(),
      'orderStatus': orderStatus,
      'createdAt': createdAt,
    };
  }
}
