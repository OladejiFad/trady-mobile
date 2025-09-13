import 'cart_item_model.dart';

class Cart {
  final String buyerPhone;
  final List<CartItem> items;

  Cart({required this.buyerPhone, required this.items});

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      buyerPhone: json['buyerPhone'],
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buyerPhone': buyerPhone,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}