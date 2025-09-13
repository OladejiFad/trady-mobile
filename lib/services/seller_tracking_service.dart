import 'dart:convert';
import 'package:http/http.dart' as http;

class SellerTrackingService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/tracking';

  // Fetch tracking info by sellerId
  static Future<Map<String, dynamic>> trackBySeller(String sellerId, String token) async {
    final url = Uri.parse('$baseUrl/seller/$sellerId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch seller tracking data: ${response.body}');
    }
  }

  // Seller updates shipment status: only seller can do this
static Future<void> updateShipmentStatus(String orderId, String status, String token) async {
  final url = Uri.parse('$baseUrl/shipment/$orderId');
  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'status': status}), // ✅ fixed key
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update shipment status: ${response.body}');
  }
}

}
