import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../global/admin_auth_data.dart';

class AdminOrderService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/admin/orders';

  // Fetch all admin orders
  static Future<List<Order>> fetchOrders() async {
    final url = Uri.parse(baseUrl);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AdminAuthData.token}',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic> && decoded['orders'] is List) {
        return (decoded['orders'] as List)
            .map((json) => Order.fromJson(json))
            .toList();
      } else {
        throw Exception('Unexpected response structure: ${decoded.runtimeType}');
      }
    } else {
      throw Exception('Failed to fetch admin orders: ${response.statusCode} ${response.body}');
    }
  }

  // Admin updates payment status or order status
  static Future<void> updateOrderStatus(String orderId, String field, String newValue) async {
    final url = Uri.parse('$baseUrl/$orderId/status');

    final body = jsonEncode({field: newValue});

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AdminAuthData.token}',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update $field: ${response.statusCode} ${response.body}');
    }
  }

// Update shipment status (now matches seller format)
static Future<void> updateShipmentStatus(String orderId, String newStatus) async {
  final url = Uri.parse('$baseUrl/$orderId/shipment-status');

  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AdminAuthData.token}',
    },
    body: jsonEncode({'status': newStatus}), // 🔄 use 'status' to match seller
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update shipment status: ${response.statusCode} ${response.body}');
  }
}

}
