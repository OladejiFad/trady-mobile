class CartItem {
  final String productId;
  final String sellerId;
  final String productName;
  final String? imageUrl;
  int quantity;
  final double price;
  final bool isBargain;
  final bool isGroupBuy;
  final String? groupBuyId;
  final String? bargainId; // ✅ NEW

  CartItem({
    required this.productId,
    required this.sellerId,
    required this.productName,
    this.imageUrl,
    required this.quantity,
    required this.price,
    required this.isBargain,
    this.isGroupBuy = false,
    this.groupBuyId,
    this.bargainId, // ✅ NEW
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'productName': productName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'price': price,
      'isBargain': isBargain,
      'isGroupBuy': isGroupBuy,
      'groupBuyId': groupBuyId,
      'bargainId': bargainId, // ✅ NEW
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productIdField = json['productId'];
    final String extractedProductId = productIdField is Map
        ? productIdField['_id'] ?? ''
        : productIdField?.toString() ?? '';

    return CartItem(
      productId: extractedProductId,
      sellerId: json['sellerId'] ?? '',
      productName: json['productName'] ?? '',
      imageUrl: json['imageUrl'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isBargain: json['isBargain'] ?? false,
      isGroupBuy: json['isGroupBuy'] ?? false,
      groupBuyId: json['groupBuyId'],
      bargainId: json['bargainId'], // ✅ NEW
    );
  }

  bool isSameItem(CartItem other) {
    return productId == other.productId &&
        isBargain == other.isBargain &&
        isGroupBuy == other.isGroupBuy &&
        groupBuyId == other.groupBuyId &&
        bargainId == other.bargainId; // ✅ Better matching
  }
}
