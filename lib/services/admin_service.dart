import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/admin_model.dart';
import '../models/seller_model.dart';
import '../models/land_lord_model.dart';
import '../models/reminder_model.dart';
import '../global/admin_auth_data.dart';

class AdminService {
  static const String baseUrl = 'http://localhost:5000/api/admin';

  // Register new admin
  static Future<String?> registerAdmin(String username, String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'phone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return null;
      } else {
        return data['message'] ?? 'Registration failed';
      }
    } catch (e) {
      return 'Error registering admin: ${e.toString()}';
    }
  }

  // Login admin and store token globally and locally
  static Future<Admin?> loginAdmin(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final admin = Admin.fromJson({...data['admin'], 'token': data['token']});
        AdminAuthData.token = admin.token;
        AdminAuthData.adminId = admin.id;
        AdminAuthData.username = admin.username;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('adminToken', admin.token);
        await prefs.setString('adminId', admin.id);
        await prefs.setString('adminUsername', admin.username);

        print('✅ Admin Token after login: ${AdminAuthData.token}');
        return admin;
      } else {
        print('❌ Login failed: ${data['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Login error: ${e.toString()}');
      return null;
    }
  }

  // Get sellers pending approval
  static Future<List<SellerModel>> getPendingSellers() async {
    final token = AdminAuthData.token;
    if (token.isEmpty) throw Exception('No admin token found. Please login first.');

    final response = await http.get(
      Uri.parse('$baseUrl/sellers/pending'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => SellerModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch pending sellers.');
    }
  }

  // Approve or reject a seller
  static Future<bool> approveOrRejectSeller(String sellerId, bool approve) async {
    final token = AdminAuthData.token;
    if (token.isEmpty) throw Exception('No admin token found. Please login first.');

    final endpoint = approve ? 'sellers/approve/$sellerId' : 'sellers/reject/$sellerId';

    final res = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return res.statusCode == 200;
  }

  // Get all sellers
  static Future<List<SellerModel>> getAllSellers() async {
    final token = AdminAuthData.token;
    if (token.isEmpty) throw Exception('No admin token found. Please login first.');

    final response = await http.get(
      Uri.parse('$baseUrl/sellers'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => SellerModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch sellers');
    }
  }

  // Ban or unban a seller
  static Future<bool> banOrUnbanSeller(String sellerId, bool ban) async {
    final token = AdminAuthData.token;
    if (token.isEmpty) throw Exception('No admin token found. Please login first.');

    final response = await http.put(
      Uri.parse('$baseUrl/sellers/$sellerId/${ban ? "ban" : "unban"}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  // Get reminders
  static Future<List<Reminder>> getReminders() async {
    final token = AdminAuthData.token;
    if (token.isEmpty) throw Exception('No admin token found. Please login first.');

    final response = await http.get(
      Uri.parse('$baseUrl/reminders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Reminder>.from(data['reminders'].map((r) => Reminder.fromJson(r)));
    } else {
      throw Exception('Failed to load reminders');
    }
  }

  // Create reminder
  static Future<bool> createReminder(String message, String scheduledAt) async {
    final token = AdminAuthData.token;
    if (token.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reminders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'scheduledAt': scheduledAt,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('❌ Error creating reminder: $e');
      return false;
    }
  }

  // Delete reminder
  static Future<bool> deleteReminder(String reminderId) async {
    final token = AdminAuthData.token;
    if (token.isEmpty) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reminders/$reminderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error deleting reminder: $e');
      return false;
    }
  }

  // ======================
  // Landlord-related methods
  // ======================

  // Get landlords pending approval
  static Future<List<LandlordModel>> getPendingLandlords() async {
    final token = AdminAuthData.token;
    if (token.isEmpty) throw Exception('No admin token found. Please login first.');

    final response = await http.get(
      Uri.parse('$baseUrl/pending-landlords'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => LandlordModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending landlords');
    }
  }

  // Approve or reject a landlord
  static Future<bool> approveOrRejectLandlord(String landlordId, bool approve) async {
    final token = AdminAuthData.token;
    if (token.isEmpty) throw Exception('No admin token found. Please login first.');

    final response = await http.put(
      Uri.parse('$baseUrl/landlord/$landlordId/approve'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'approve': approve}),
    );

    return response.statusCode == 200;
  }

 static Future<bool> banLandlord(String landlordId) async {
  final response = await http.put(
    Uri.parse('$baseUrl/landlords/$landlordId/ban'), // ✅ no extra /admin
    headers: {'Authorization': 'Bearer ${AdminAuthData.token}'},
  );
  return response.statusCode == 200;
}

static Future<bool> unbanLandlord(String landlordId) async {
  final response = await http.put(
    Uri.parse('$baseUrl/landlords/$landlordId/unban'), // ✅ consistent
    headers: {'Authorization': 'Bearer ${AdminAuthData.token}'},
  );
  return response.statusCode == 200;
}
static Future<List<LandlordModel>> getApprovedLandlords() async {
  final response = await http.get(
    Uri.parse('$baseUrl/landlords'),
    headers: {'Authorization': 'Bearer ${AdminAuthData.token}'},
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data as List).map((json) => LandlordModel.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load landlords');
  }
}

}
