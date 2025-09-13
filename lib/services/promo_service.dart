import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/promo_model.dart';
import '../global/auth_data.dart'; // ✅ Where token is stored

class PromoService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/promo';

  // ✅ For seller (logged-in) promo fetching
  static Future<List<Promo>> fetchSellerPromosForSelf() async {
    final response = await http.get(
      Uri.parse('$baseUrl/seller'),
      headers: {'Authorization': 'Bearer ${AuthData.token}'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Promo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch your promos');
    }
  }

  // ✅ For buyer viewing any seller’s promos (requires backend route GET /promo/seller/:id)
  static Future<List<Promo>> fetchSellerPromos(String sellerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/seller/$sellerId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Promo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch seller promos');
    }
  }

  static Future<void> createPromo(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer ${AuthData.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to create promo');
    }
  }

  static Future<void> deletePromo(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer ${AuthData.token}'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete promo');
    }
  }

  static Future<Map<String, dynamic>> validatePromo(String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Invalid promo code');
    }
    return data;
  }
}
