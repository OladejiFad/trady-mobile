import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_model.dart';
import '../global/admin_auth_data.dart';  // Import your global admin auth data

class AdminPropertyService {
  final String baseUrl = 'http://172.20.10.2:5000/api/admin/properties';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AdminAuthData.token}',
      };

  Future<List<Property>> fetchPendingProperties() async {
    final url = Uri.parse('$baseUrl/pending');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Property.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending properties');
    }
  }

  Future<void> approveProperty(String propertyId) async {
    final url = Uri.parse('$baseUrl/verify/$propertyId');
    final response = await http.put(url, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to approve property');
    }
  }

  Future<void> rejectProperty(String propertyId) async {
    final url = Uri.parse('$baseUrl/$propertyId/reject');
    final response = await http.post(url, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to reject property');
    }
  }
}
