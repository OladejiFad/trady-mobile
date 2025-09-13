import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthData {
  static String token = '';
  static String adminId = '';
  static String username = '';

  // Save data persistently with consistent keys
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adminToken', token);
    await prefs.setString('adminId', adminId);
    await prefs.setString('adminUsername', username);
  }

  // Load data from persistent storage with consistent keys
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('adminToken') ?? '';
    adminId = prefs.getString('adminId') ?? '';
    username = prefs.getString('adminUsername') ?? '';
  }

  // Clear saved data
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('adminToken');
    await prefs.remove('adminId');
    await prefs.remove('adminUsername');
    token = '';
    adminId = '';
    username = '';
  }
}
