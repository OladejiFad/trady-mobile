import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class MarketService {
  // Automatically choose the correct backend URL
  static final String baseUrl = kIsWeb
      ? 'http://172.20.10.2:5000/api/market-status' // Web uses LAN IP
      : 'http://localhost:5000/api/market-status'; // Mobile/Desktop uses localhost

  /// Fetch only active status (true/false)
  static Future<bool> fetchMarketDayStatus(String role) async {
    try {
      final uri = Uri.parse('$baseUrl?role=$role');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[MarketService.fetchMarketDayStatus] $data');
        return data['active'] as bool;
      } else {
        print('[MarketService.fetchMarketDayStatus] Failed with status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[MarketService.fetchMarketDayStatus] Exception: $e');
      return false;
    }
  }

  /// Fetch full Market Day info (used in UI banners)
  static Future<Map<String, dynamic>?> fetchMarketDayInfo(String role) async {
    try {
      final uri = Uri.parse('$baseUrl?role=$role');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('[MarketService.fetchMarketDayInfo] $result');
        return result;
      } else {
        print('[MarketService.fetchMarketDayInfo] Failed with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[MarketService.fetchMarketDayInfo] Exception: $e');
      return null;
    }
  }
}
