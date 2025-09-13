// lib/services/store_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/store_model.dart';
import '../global/auth_data.dart';

class StoreService {
  static const String sellerBaseUrl = 'http://172.20.10.2:5000/api/seller/store';
  // ✅ Fixed: use same prefix for public routes
  static const String publicBaseUrl = 'http://172.20.10.2:5000/api/seller/store';

  Map<String, String> _getAuthHeaders() {
    if (AuthData.token == null || AuthData.token!.isEmpty) {
      throw Exception('Missing auth token. Please log in.');
    }
    return {
      'Authorization': 'Bearer ${AuthData.token}',
      'Content-Type': 'application/json',
    };
  }

  Future<Store?> fetchMyStore() async {
    try {
      final response = await http.get(
        Uri.parse('$sellerBaseUrl/my-store'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Store.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        print('Failed to fetch store: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Fetch store error: $e');
      return null;
    }
  }

  Future<bool> setupOrUpdateStore(Store store) async {
    try {
      final Map<String, dynamic> storeData = store.toJson();

      if (store.id.isNotEmpty) {
        if (store.storeNameLocked) storeData.remove('storeName');
        if (store.occupationTypeLocked) storeData.remove('occupationType');
        // Removed storeOccupationLocked - check your model
      }

      final response = await http.post(
        Uri.parse('$sellerBaseUrl/setup'),
        headers: _getAuthHeaders(),
        body: json.encode(storeData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to setup/update store: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Setup/update store error: $e');
      return false;
    }
  }

  Future<Store?> fetchStoreBySellerId(String sellerId) async {
    try {
      final response = await http.get(
        Uri.parse('$publicBaseUrl/public/$sellerId'),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('store')) {
          return Store.fromJson(decoded['store']);
        } else {
          print('Unexpected store data format: $decoded');
          return null;
        }
      } else {
        print('Error fetching store by sellerId: ${response.body}');
        return null;
      }
    } catch (e) {
      print('fetchStoreBySellerId error: $e');
      return null;
    }
  }

  Future<List<Store>> fetchStores({String? type}) async {
    try {
      final uri = Uri.parse(type != null
          ? '$publicBaseUrl/filtered?type=$type'
          : '$publicBaseUrl/filtered');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('stores')) {
          final List<dynamic> data = decoded['stores'];
          return data.map((json) => Store.fromJson(json)).toList();
        } else {
          print('Unexpected stores data format: $decoded');
          return [];
        }
      } else {
        print('Failed to fetch stores: ${response.body}');
        return [];
      }
    } catch (e) {
      print('fetchStores error: $e');
      return [];
    }
  }

  Future<List<Store>> fetchSkillWorkerStores() async {
    return fetchStores(type: 'skillworker');
  }

  Future<List<Store>> fetchVendorStores() async {
  return fetchStores(type: 'vendor');
}

  Future<Map<String, dynamic>> fetchSellerProfile() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.20.10.2:5000/api/auth/profile'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch seller profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Fetch seller profile error: $e');
    }
  }
  

}
