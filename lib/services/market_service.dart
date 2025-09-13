import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/market-status';

  // Used in simple checks (returns only true/false)
  static Future<bool> fetchMarketDayStatus(String role) async {
    final uri = Uri.parse('$baseUrl?role=$role');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('[MarketService.fetchMarketDayStatus] $data');
      return data['active'] as bool;
    } else {
      throw Exception('Failed to fetch Market Day status');
    }
  }

  // Used in MarketDayBanner (returns full info)
  static Future<Map<String, dynamic>> fetchMarketDayInfo(String role) async {
    final uri = Uri.parse('$baseUrl?role=$role');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      print('[MarketService.fetchMarketDayInfo] $result');
      return result;
    } else {
      throw Exception('Failed to fetch Market Day info');
    }
  }
}
