import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/complaint_model.dart';

class ComplaintService {
  static const baseUrl = 'http://172.20.10.2:5000/api/complaints';

  // Fetch all complaints (Admin only)
  static Future<List<Complaint>> fetchAllComplaints(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Complaint.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load complaints: ${response.body}');
    }
  }

  // Resolve a complaint (Admin only)
  static Future<void> resolveComplaint(String token, String id, String responseText) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'response': responseText}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to resolve complaint: ${response.body}');
    }
  }

  // Create a complaint (Buyer or Seller)
  static Future<Complaint> createComplaint({
    required String token,
    required String subject,
    required String description,
    String? buyerPhone,
    String? sellerId,
  }) async {
    if (buyerPhone == null && sellerId == null) {
      throw Exception('Either buyerPhone or sellerId must be provided');
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'subject': subject,
        'description': description,
        'buyerPhone': buyerPhone,
        'sellerId': sellerId,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Complaint.fromJson(data['complaint']);
    } else {
      throw Exception('Failed to submit complaint: ${response.body}');
    }
  }

  // Get complaints by userId (buyerPhone or sellerId)
static Future<List<Complaint>> getComplaintsByUser(String userId) async {
  final response = await http.get(Uri.parse('$baseUrl/user/$userId'));

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((e) => Complaint.fromJson(e)).toList();
  } else {
    throw Exception('Failed to fetch complaints: ${response.body}');
  }
}

}