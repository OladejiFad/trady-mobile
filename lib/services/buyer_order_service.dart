import 'dart:convert';
import 'package:http/http.dart' as http;

class BuyerOrderService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/orders';
  static const String groupBuyBase = 'http://172.20.10.2:5000/api/groupbuys';

  /// Fetch all orders for a buyer
  Future<List<dynamic>> getOrders(String buyerPhone) async {
    final url = Uri.parse('$baseUrl/buyer/$buyerPhone');
    print('📤 GET $url');

    final response = await http.get(url);
    print('📥 Response ${response.statusCode}: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['orders'] ?? [];
    } else {
      throw Exception('❌ Failed to load orders: ${response.body}');
    }
  }

  /// Fetch final items (cart + accepted bargains + active group buys)
  Future<List<dynamic>> fetchFinalItems(String buyerPhone) async {
    final url = Uri.parse('$baseUrl/items/$buyerPhone');
    print('📤 GET $url');

    final response = await http.get(url);
    print('📥 Response ${response.statusCode}: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('❌ Failed to fetch cart/bargain items: ${response.body}');
    }

    final data = jsonDecode(response.body);
    List<dynamic> items = data['items'] ?? [];

    // 🔄 Then fetch group buys and append those that are not yet ordered
    final gbUrl = Uri.parse('$groupBuyBase/eligible/$buyerPhone');
    print('📤 GET $gbUrl');

    final gbResponse = await http.get(gbUrl);
    print('📥 GroupBuy ${gbResponse.statusCode}: ${gbResponse.body}');

    if (gbResponse.statusCode == 200) {
      final gbData = jsonDecode(gbResponse.body);
      final groupBuyItems = gbData['items'] ?? [];

      // ✅ Only add if not already in items (dedupe by productId)
      final existingIds = items.map((e) => e['productId'].toString()).toSet();
      for (var item in groupBuyItems) {
        if (!existingIds.contains(item['productId'].toString())) {
          items.add({
            ...item,
            'isGroupBuy': true,
            'source': 'groupbuy',
          });
        }
      }
    }

    return items;
  }

  /// Place order
  Future<String> placeOrder({
    required String buyerName,
    required String buyerPhone,
    required String buyerLocation,
    required List<Map<String, dynamic>> products,
  }) async {
    final url = Uri.parse('$baseUrl/place');
    final body = jsonEncode({
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerLocation': buyerLocation,
      'products': products,
    });

    print('📤 POST $url');
    print('📦 Payload: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('📥 Response ${response.statusCode}: ${response.body}');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['orderId'];
    } else {
      throw Exception('❌ Failed to place order: ${response.body}');
    }
  }
}
