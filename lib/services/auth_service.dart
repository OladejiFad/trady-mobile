import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global/auth_data.dart';

const String baseUrl = 'http://172.20.10.2:5000/api/auth';

// Register Seller (with occupation, jobType, idCard, nin)
Future<String> registerSeller({
  required String name,
  required String phone,
  required String password,
  required String location,
  required String occupation,   // 'Skill Workers' or 'Vendor'
  required String jobType,
  String? idCard,
  required String nin,
}) async {
  final body = {
    'name': name,
    'phone': phone,
    'password': password,
    'location': location,
    'occupation': occupation,
    'occupationType': jobType,
    'nin': nin,
  };

  if (occupation == 'Skill Workers' && idCard != null) {
    body['idCard'] = idCard;
  }

  final response = await http.post(
    Uri.parse('$baseUrl/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (response.statusCode == 201) {
    return jsonDecode(response.body)['message'];
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to register seller');
  }
}

// Register Landlord
Future<String> registerLandlord({
  required String name,
  required String phone,
  required String password,
  required String location,
  required String bvn,
  String? nin,
  String? internationalPassport,
}) async {
  final body = {
    'name': name,
    'phone': phone,
    'password': password,
    'location': location,
    'bvn': bvn,
    'nin': nin,
    'internationalPassport': internationalPassport,
  };

  final response = await http.post(
    Uri.parse('$baseUrl/register-landlord'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (response.statusCode == 201) {
    return jsonDecode(response.body)['message'];
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to register landlord');
  }
}

// Login Seller or Landlord, returns full response with token & user info
Future<Map<String, dynamic>> loginUser({
  required String phone,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'phone': phone,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);
    final user = result['user'];
    final role = user['role'] ?? '';

    AuthData.token = result['token'];

    // Clear previous IDs
    AuthData.sellerId = '';
    AuthData.landlordId = '';

    if (role == 'seller') {
      AuthData.sellerId = user['id'];
    } else if (role == 'landlord') {
      AuthData.landlordId = user['id'];
    }

    return result;
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Login failed');
  }
}

// Get Seller Profile (protected)
Future<Map<String, dynamic>> getSellerProfile() async {
  final response = await http.get(
    Uri.parse('$baseUrl/profile'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AuthData.token}',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to fetch seller profile');
  }
}

// Get Landlord Profile (protected)
Future<Map<String, dynamic>> getLandlordProfile() async {
  final response = await http.get(
    Uri.parse('$baseUrl/landlord-profile'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AuthData.token}',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to fetch landlord profile');
  }
}
