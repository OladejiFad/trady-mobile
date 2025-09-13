import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; 
import '../models/bargain_model.dart';

const String baseUrl = 'http://172.20.10.2:5000/api/bargain';

class BargainService {
  final String? sellerAuthToken;
  final String? buyerAuthToken;
  final Duration timeoutDuration;

  BargainService({
    this.sellerAuthToken,
    this.buyerAuthToken,
    this.timeoutDuration = const Duration(seconds: 10),
  });

  Bargain _parseBargain(String responseBody) {
    final data = jsonDecode(responseBody);
    if (data is Map<String, dynamic> && data.containsKey('bargain')) {
      return Bargain.fromJson(data['bargain']);
    } else {
      return Bargain.fromJson(data);
    }
  }

  List<Bargain> _parseBargainList(String responseBody) {
    final data = jsonDecode(responseBody);
    if (data is List) {
      return data.map((json) => Bargain.fromJson(json)).toList();
    } else if (data is Map<String, dynamic>) {
      if (data.containsKey('bargains') && data['bargains'] is List) {
        return (data['bargains'] as List)
            .map((json) => Bargain.fromJson(json))
            .toList();
      } else if (data.containsKey('data') && data['data'] is List) {
        return (data['data'] as List)
            .map((json) => Bargain.fromJson(json))
            .toList();
      }
    }
    throw Exception('Unexpected response format for bargain list');
  }

  Future<List<Bargain>> getSellerBargains() async {
    final url = Uri.parse('$baseUrl/seller');
    final response = await http.get(
      url,
      headers: {
        if (sellerAuthToken != null) 'Authorization': 'Bearer $sellerAuthToken',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      return _parseBargainList(response.body);
    } else {
      throw Exception('Failed to fetch seller bargains (${response.statusCode}): ${response.body}');
    }
  }

Future<Bargain> _postRespondToBargain({
  required String urlPath,
  required String bargainId,
  required String action,
  List<Map<String, dynamic>>? items,
  double? totalPrice,
  Map<String, String>? headers,
  bool isBuyer = false,
}) async {
  final url = Uri.parse('$baseUrl/$urlPath');

  // ✅ Correct type
  final Map<String, dynamic> body = {
    'bargainId': bargainId,
    'action': action,
  };

  if (action == 'counter') {
    if (items == null || totalPrice == null) {
      throw Exception('Items and totalPrice are required for counter action');
    }
    body['items'] = items;
    body['totalCounterPrice'] = totalPrice;
  }

  final response = await http
      .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (headers != null) ...headers,
        },
        body: jsonEncode(body),
      )
      .timeout(timeoutDuration);

  if (response.statusCode == 200) {
    return _parseBargain(response.body);
  } else {
    throw Exception(
        'Failed to respond to bargain (${response.statusCode}): ${response.body}');
  }
}


  Future<Bargain> respondToBargain({
    required String bargainId,
    required String action,
    List<Map<String, dynamic>>? items,
    double? totalCounterPrice,
  }) {
    return _postRespondToBargain(
      urlPath: 'respond',
      bargainId: bargainId,
      action: action,
      items: items,
      totalPrice: totalCounterPrice,
      headers: sellerAuthToken != null
          ? {'Authorization': 'Bearer $sellerAuthToken'}
          : null,
    );
  }

  Future<Bargain> buyerRespondToBargain({
    required String bargainId,
    required String action,
    required List<Map<String, dynamic>> items,
    required double totalCounterPrice,
  }) {
    return _postRespondToBargain(
      urlPath: 'buyer/respond',
      bargainId: bargainId,
      action: action,
      items: items,
      totalPrice: totalCounterPrice,
      isBuyer: true,
      headers: buyerAuthToken != null
          ? {'Authorization': 'Bearer $buyerAuthToken'}
          : null,
    );
  }

Future<Bargain> startOrContinueBargain({
  required List<Map<String, dynamic>> items,
  required double totalOfferedPrice,
  required String buyerName,
  required String buyerPhone,
  required String note, // ✅ Add this parameter
}) async {
  final url = Uri.parse('$baseUrl/start');
  final response = await http
      .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (buyerAuthToken != null) 'Authorization': 'Bearer $buyerAuthToken',
        },
        body: jsonEncode({
          'items': items,
          'totalOfferedPrice': totalOfferedPrice,
          'buyerName': buyerName,
          'buyerPhone': buyerPhone,
          'note': note, // ✅ Include in payload
        }),
      )
      .timeout(timeoutDuration);

  if (response.statusCode == 200) {
    return _parseBargain(response.body);
  } else {
    throw Exception('Failed to start bargain (${response.statusCode}): ${response.body}');
  }
}


  Future<List<Bargain>> getBuyerBargains(String buyerPhone) async {
    final url = Uri.parse('$baseUrl/buyer?buyerPhone=$buyerPhone');
    final response = await http.get(
      url,
      headers: {
        if (buyerAuthToken != null) 'Authorization': 'Bearer $buyerAuthToken',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      return _parseBargainList(response.body);
    } else {
      throw Exception('Failed to fetch buyer bargains (${response.statusCode}): ${response.body}');
    }
  }

  Future<Bargain> getBargainDetail(String bargainId, String buyerPhone) async {
    final uri = Uri.parse('$baseUrl/$bargainId?buyerPhone=$buyerPhone');
    final response = await http.get(uri).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data.containsKey('bargain')
          ? Bargain.fromJson(data['bargain'])
          : Bargain.fromJson(data);
    } else {
      throw Exception('Failed to fetch bargain detail: ${response.body}');
    }
  }


  Future<void> rejectSellerOffer({required String bargainId}) async {
    final url = Uri.parse('$baseUrl/buyer/reject');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            if (buyerAuthToken != null) 'Authorization': 'Bearer $buyerAuthToken',
          },
          body: jsonEncode({'bargainId': bargainId}),
        )
        .timeout(timeoutDuration);

    if (response.statusCode != 200) {
      throw Exception('Failed to reject seller offer (${response.statusCode}): ${response.body}');
    }
  }

  Future<List<String>> getAvailableProductIdsForBuyer() async {
    final url = Uri.parse('http://172.20.10.2:5000/api/products/available');
    final response = await http.get(
      url,
      headers: {
        if (buyerAuthToken != null) 'Authorization': 'Bearer $buyerAuthToken',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .where((item) => item['id'] != null)
          .map((item) => item['id'].toString())
          .toList();
    } else {
      throw Exception('Failed to load available product IDs (${response.statusCode})');
    }
  }

  Future<void> acceptBuyerOffer({
    required String bargainId,
    required double acceptedPrice,
  }) async {
    final url = Uri.parse('$baseUrl/seller/accept');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            if (sellerAuthToken != null) 'Authorization': 'Bearer $sellerAuthToken',
          },
          body: jsonEncode({
            'bargainId': bargainId,
            'acceptedPrice': acceptedPrice,
          }),
        )
        .timeout(timeoutDuration);

    if (response.statusCode != 200) {
      throw Exception('Failed to accept buyer offer (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> acceptSellerOffer({
  required String bargainId,
  double? acceptedPrice, // optional
}) async {
  final url = Uri.parse('$baseUrl/accept-seller-offer');
  final body = {
    'bargainId': bargainId,
    if (acceptedPrice != null) 'acceptedPrice': acceptedPrice,
  };

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  ).timeout(timeoutDuration);

  if (response.statusCode != 200) {
    debugPrint('❌ acceptSellerOffer failed: ${response.body}');
    throw Exception('Failed to accept seller offer');
  }

  debugPrint('✅ Seller offer accepted');
}

Future<List<Bargain>> getSuccessfulBargains(String buyerPhone) async {
  final url = Uri.parse('$baseUrl/successful/$buyerPhone');

  final response = await http.get(url).timeout(timeoutDuration);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Bargain.fromJson(json)).toList();
  } else if (response.statusCode == 404 || response.body.trim().isEmpty) {
    debugPrint('No successful bargains found for $buyerPhone');
    return [];
  } else {
    throw Exception('Failed to fetch successful bargains (${response.statusCode}): ${response.body}');
  }
}




Future<Bargain?> fetchLatestAcceptedBargain(String productId) async {
    final res = await http.get(Uri.parse('$baseUrl/$productId'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return Bargain.fromJson(data);
    }
    return null;
  }

  // ✅ NEW: Add to cart from bargain
 Future<bool> addToCartFromBargain({
  required String bargainId,
  required String buyerPhone,
}) async {
  final url = Uri.parse('$baseUrl/$bargainId/add-to-cart');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'buyerPhone': buyerPhone}),
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      print('✅ Bargain items added to cart');
      return true;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      print('❌ Failed to add to cart: $error');
      return false;
    }
  } catch (e) {
    print('Error in addToCartFromBargain: $e');
    return false;
  }
}
  

 
  Future<Map<String, dynamic>> fetchProductById(String productId) async {
    final url = Uri.parse('http://172.20.10.2:5000/api/products/$productId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch product with ID $productId');
    }
  }


}