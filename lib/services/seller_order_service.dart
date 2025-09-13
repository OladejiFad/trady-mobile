import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart'; // Ensure the path is correct

class SellerOrderService {
  static const String _baseUrl = 'http://172.20.10.2:5000/api/orders';

  static Future<List<Order>> fetchSellerOrders(String sellerId, String token, {int? limit}) async {
    final url = Uri.parse('$_baseUrl/seller/$sellerId${limit != null ? '?limit=$limit' : ''}');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final ordersJson = data['orders'] as List<dynamic>? ?? [];
      return ordersJson
          .where((json) => json != null)
          .map((json) => Order.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to fetch seller orders: ${response.body}');
    }
  }
}
