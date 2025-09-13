import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // ✅ For kDebugMode
import '../models/cart_item_model.dart';

class CartService {
  static const String baseUrl = 'http://172.20.10.2:5000';

  final List<CartItem> _localCart = [];

  List<CartItem> get localCart => _localCart;

  // ✅ Add to local cart with duplication check
  void addToCart({
    required String productId,
    required String sellerId,
    required String productName,
    required String? imageUrl,
    required double price,
    required int quantity,
    bool isBargain = false,
    bool isGroupBuy = false,
    String? groupBuyId,
    String? bargainId,
  }) {
final newItem = CartItem(
  productId: productId,
  sellerId: sellerId,
  productName: productName,
  imageUrl: imageUrl,
  price: price,
  quantity: quantity,
  isBargain: isBargain,
  isGroupBuy: isGroupBuy,
  groupBuyId: groupBuyId,
  bargainId: bargainId,
);

final exists = _localCart.any((item) => item.isSameItem(newItem));

if (!exists) {
  _localCart.add(newItem);
}


  }

  void removeItem(
    String productId, {
    bool isBargain = false,
    bool isGroupBuy = false,
    String? groupBuyId,
  }) {
    _localCart.removeWhere((item) =>
        item.productId == productId &&
        item.isBargain == isBargain &&
        item.isGroupBuy == isGroupBuy &&
        item.groupBuyId == groupBuyId);
  }

  void clearCart() {
    _localCart.clear();
  }

  // ✅ Sync cart to backend only
  Future<void> syncToBackend(String phone) async {
    final url = Uri.parse('$baseUrl/api/cart/sync/$phone');

    final cartItemsJson = _localCart.map((item) => item.toJson()).toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cartItems': cartItemsJson}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync cart: ${response.statusCode}');
    }
  }

  // ✅ Sync to backend, then fetch and update local cart
  Future<void> syncCartAndLoad(String buyerPhone) async {
    await syncToBackend(buyerPhone);
    final items = await fetchCart(buyerPhone);
    if (items != null) {
      _localCart
        ..clear()
        ..addAll(items);
    }
  }

  Future<void> markGroupBuysAsUsed(String buyerPhone) async {
    final groupBuyIds = _localCart
        .where((item) => item.isGroupBuy)
        .map((item) => item.groupBuyId)
        .whereType<String>()
        .toSet()
        .toList();

    if (groupBuyIds.isEmpty) return;

    final url = Uri.parse('$baseUrl/api/groupbuys/mark-used');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'groupBuyIds': groupBuyIds,
        'buyerPhone': buyerPhone,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark group buys as used');
    }
  }

  Future<void> markBargainsAsUsed(String buyerPhone) async {
    final bargainIds = _localCart
        .where((item) => item.isBargain)
        .map((item) => item.bargainId)
        .whereType<String>() // filters out nulls
        .toSet()
        .toList();


    if (bargainIds.isEmpty) return;

    final url = Uri.parse('$baseUrl/api/bargain/mark-used');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'bargainIds': bargainIds}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark bargains as used');
    }
  }

  // ✅ Finalize order then clean up cart
  Future<void> placeOrder(String phone, String buyerName, String location) async {
    final url = Uri.parse('$baseUrl/api/orders/items/$phone');

    final body = {
      'name': buyerName,
      'location': location,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      await markGroupBuysAsUsed(phone);
      await markBargainsAsUsed(phone);
      clearCart();
    } else {
      throw Exception('Order failed: ${response.body}');
    }
  }

  // ✅ Fetch merged cart from backend
  Future<List<CartItem>?> fetchCart(String phone) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/cart/$phone'));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (kDebugMode) {
          print('✅ Cart response decoded: $decoded');
        }

        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }

        if (decoded is Map && decoded['items'] is List) {
          return (decoded['items'] as List)
              .whereType<Map>()
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }

        if (decoded is Map && decoded.containsKey('productId')) {
          return [CartItem.fromJson(Map<String, dynamic>.from(decoded))];
        }

        if (kDebugMode) {
          print('⚠️ Unhandled cart structure: $decoded');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch cart: ${res.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception during fetchCart: $e');
      }
    }

    return null;
  }
}
