import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/group_buy_model.dart';
import '../global/auth_data.dart';

class GroupBuyService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/groupbuys';

  /// Fetch all public group buys (for buyers or guests)
  Future<List<GroupBuy>> fetchAllGroupBuys() async {
    final url = Uri.parse('$baseUrl/public');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => GroupBuy.fromJson(json)).toList();
    } else {
      throw Exception('❌ Failed to fetch group buys: ${response.body}');
    }
  }

  /// Create a group buy (seller only)
  Future<void> createGroupBuy({
    required String productId,
    required String title,
    required String description,
    required double pricePerUnit,
    required int minParticipants,
    required DateTime deadline,
  }) async {
    final token = AuthData.token;
    final url = Uri.parse('$baseUrl/create');

    final body = jsonEncode({
      'productId': productId,
      'title': title,
      'description': description,
      'pricePerUnit': pricePerUnit,
      'minParticipants': minParticipants,
      'deadline': deadline.toIso8601String(),
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode != 201) {
      throw Exception('❌ Failed to create group buy: ${response.body}');
    }
  }

  /// Join a group buy (buyer or guest)
  Future<GroupBuy> joinGroupBuy({
    required String groupId,
    required GroupParticipant participant,
  }) async {
    final url = Uri.parse('$baseUrl/join/$groupId');
    final body = jsonEncode(participant.toJson());

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return GroupBuy.fromJson(jsonBody['group']);
    } else {
      throw Exception('❌ Failed to join group buy: ${response.body}');
    }
  }

  /// Fetch group buys created by this seller
  Future<List<GroupBuy>> fetchSellerGroupBuys() async {
    final token = AuthData.token;
    final url = Uri.parse('$baseUrl/seller');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => GroupBuy.fromJson(json)).toList();
    } else {
      throw Exception('❌ Failed to fetch seller group buys: ${response.body}');
    }
  }

  /// Update a group buy
  Future<void> updateGroupBuy({
    required String groupBuyId,
    required String title,
    required String description,
    required double pricePerUnit,
    required int minParticipants,
    required DateTime deadline,
  }) async {
    final token = AuthData.token;
    final url = Uri.parse('$baseUrl/$groupBuyId');

    final body = jsonEncode({
      'title': title,
      'description': description,
      'pricePerUnit': pricePerUnit,
      'minParticipants': minParticipants,
      'deadline': deadline.toIso8601String(),
    });

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Failed to update group buy: ${response.body}');
    }
  }

  /// Delete a group buy
  Future<void> deleteGroupBuy(String groupBuyId) async {
    final token = AuthData.token;
    final url = Uri.parse('$baseUrl/$groupBuyId');

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Failed to delete group buy: ${response.body}');
    }
  }

  /// Toggle group buy visibility
  Future<void> toggleGroupBuyVisibility(String groupBuyId, bool visible) async {
    final token = AuthData.token;
    final url = Uri.parse('$baseUrl/visibility/$groupBuyId');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'visible': visible}),
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Failed to update visibility: ${response.body}');
    }
  }

  /// Pay for group buy (adds to paidParticipants)
  Future<void> payForGroupBuy(String groupBuyId, String phone, {int quantity = 1}) async {
    final url = Uri.parse('$baseUrl/pay/$groupBuyId');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'quantity': quantity}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to pay for group buy');
    }
  }

  /// Add paid group buy to cart
  Future<void> addToCartFromGroupBuy(String groupBuyId, String phone) async {
    final url = Uri.parse('$baseUrl/$groupBuyId/add-to-cart');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Failed to add to cart: ${response.body}');
    }
  }

  /// ✅ Merge successful group buys into cart and mark them as used
 Future<void> mergeSuccessfulGroupBuysIntoCart(String buyerPhone, Function addToCart) async {
  final groupBuyUrl = Uri.parse('$baseUrl/successful/$buyerPhone');
  final groupBuyResponse = await http.get(groupBuyUrl);

  if (groupBuyResponse.statusCode != 200) {
    throw Exception('Failed to fetch successful group buys: ${groupBuyResponse.statusCode}');
  }

  final List<dynamic> groupBuysJson = jsonDecode(groupBuyResponse.body);
  final List<String> usedGroupBuyIds = [];

  for (var itemJson in groupBuysJson) {
    addToCart(
      productId: itemJson['productId'] ?? '',
      sellerId: (itemJson['sellerId'] ?? '').toString(),
      productName: itemJson['productName'] ?? '',
      imageUrl: itemJson['imageUrl'] ?? '',
      price: (itemJson['price'] as num).toDouble(),
      quantity: itemJson['quantity'] ?? 1,
      isBargain: false,
      isGroupBuy: true,
    );

    if (itemJson['groupBuyId'] != null) {
      usedGroupBuyIds.add(itemJson['groupBuyId']);
    }
  }

  if (usedGroupBuyIds.isNotEmpty) {
    final markUrl = Uri.parse('$baseUrl/mark-used');
    final markResponse = await http.post(
      markUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'groupBuyIds': usedGroupBuyIds,
        'buyerPhone': buyerPhone,  // <-- Add buyerPhone here!
      }),
    );

    if (markResponse.statusCode != 200) {
      throw Exception('Failed to mark group buys as used: ${markResponse.body}');
    }
  }
}

static Future<List<GroupBuy>> fetchGroupBuysBySeller(String sellerId) async {
  final response = await http.get(Uri.parse('$baseUrl/api/group-buys?sellerId=$sellerId'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => GroupBuy.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load group buys for seller');
  }
}


}
