import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';
import '../global/auth_data.dart';

class ReviewService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/reviews';

  // Get reviews for any target (e.g., product or store)
  static Future<List<Review>> fetchReviews(String targetType, String targetId) async {
    print('[ReviewService.fetchReviews] Fetching reviews for $targetType/$targetId');
    final response = await http.get(Uri.parse('$baseUrl/$targetType/$targetId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> reviewList = data['reviews'];
      print('[ReviewService.fetchReviews] Received ${reviewList.length} reviews');
      return reviewList.map((json) => Review.fromJson(json)).toList();
    } else {
      print('[ReviewService.fetchReviews] Failed with status ${response.statusCode}');
      throw Exception('Failed to load reviews');
    }
  }

  // Add a review
  static Future<void> addReview({
    required String targetId,
    required String targetType,
    required double rating,
    required String message,
  }) async {
    final token = AuthData.token;

    print('[ReviewService.addReview] Sending review:');
    print('targetId: $targetId');
    print('targetType: $targetType');
    print('rating: $rating');
    print('message: $message');
    print('buyerPhone: ${AuthData.buyerPhone}');
    print('buyerName: ${AuthData.buyerName}');

    final response = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'targetId': targetId,
        'targetType': targetType,
        'rating': rating,
        'message': message,
        'buyerPhone': AuthData.buyerPhone,
        'buyerName': AuthData.buyerName,
      }),
    );

    print('[ReviewService.addReview] Response status: ${response.statusCode}');
    print('[ReviewService.addReview] Response body: ${response.body}');

    if (response.statusCode != 201) {
      throw Exception('Failed to add review: ${response.body}');
    }
  }
}
