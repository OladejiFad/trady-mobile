import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';
import '../global/auth_data.dart';       // buyer & seller
import '../global/admin_auth_data.dart'; // admin

class TrackingService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/tracking';

  // 🔍 Fetch tracking data for buyer + save token if present
  static Future<Map<String, dynamic>> trackByBuyer(String buyerPhone) async {
    final url = Uri.parse('$baseUrl/buyer');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'buyerPhone': buyerPhone}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // ✅ Store token for future satisfaction updates
      if (data['token'] != null) {
        AuthData.token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('buyerToken', data['token']);
      }

      return data;
    } else {
      throw Exception('Failed to fetch tracking data: ${response.body}');
    }
  }

  // 🛡 Update satisfaction status (token required — auto-load if missing)
  static Future<void> updateSatisfactionStatus(
    String orderId,
    String newStatus,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/satisfaction/$orderId');

    // If no token provided, try to load from saved data
    String finalToken = token;
    if (finalToken.isEmpty) {
      finalToken = AuthData.token;
    }

    if (finalToken.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      finalToken = prefs.getString('buyerToken') ?? '';
      AuthData.token = finalToken;
    }

    if (finalToken.isEmpty) {
      throw Exception('Missing authentication token');
    }

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $finalToken',
      },
      body: jsonEncode({'satisfactionStatus': newStatus}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update satisfaction status: ${response.statusCode} ${response.body}');
    }
  }
}
