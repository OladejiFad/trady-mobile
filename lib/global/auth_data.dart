import 'package:shared_preferences/shared_preferences.dart';

class AuthData {
  static String token = '';
  static String sellerId = '';
  static String buyerPhone = '';
  static String buyerName = '';
  static String landlordId = '';
  static String landlordName = '';
  static String? role; // 'buyer' or 'landlord'
  static String? username;

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('sellerId', sellerId);
    await prefs.setString('buyerPhone', buyerPhone);
    await prefs.setString('buyerName', buyerName);
    await prefs.setString('landlordId', landlordId);
    await prefs.setString('landlordName', landlordName);
    if (role != null) await prefs.setString('role', role!);
    if (username != null) await prefs.setString('username', username!);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    sellerId = prefs.getString('sellerId') ?? '';
    buyerPhone = prefs.getString('buyerPhone') ?? '';
    buyerName = prefs.getString('buyerName') ?? '';
    landlordId = prefs.getString('landlordId') ?? '';
    landlordName = prefs.getString('landlordName') ?? '';
    role = prefs.getString('role');
    username = prefs.getString('username');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('sellerId');
    await prefs.remove('buyerPhone');
    await prefs.remove('buyerName');
    await prefs.remove('landlordId');
    await prefs.remove('landlordName');
    await prefs.remove('role');
    await prefs.remove('username');
    token = '';
    sellerId = '';
    buyerPhone = '';
    buyerName = '';
    landlordId = '';
    landlordName = '';
    role = null;
    username = null;
  }
}











/*import 'package:shared_preferences/shared_preferences.dart';

class AuthData {
  static String token = '';
  static String sellerId = '';
  static String buyerPhone = '';
  static String buyerName = '';
  static String landlordId = '';
  static String landlordName = '';
  static String? role;
  static String? username;

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('sellerId', sellerId);
    await prefs.setString('buyerPhone', buyerPhone);
    await prefs.setString('buyerName', buyerName);
    await prefs.setString('landlordId', landlordId);
    await prefs.setString('landlordName', landlordName);
    if (role != null) await prefs.setString('role', role!);
    if (username != null) await prefs.setString('username', username!);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    sellerId = prefs.getString('sellerId') ?? '';
    buyerPhone = prefs.getString('buyerPhone') ?? '';
    buyerName = prefs.getString('buyerName') ?? '';
    landlordId = prefs.getString('landlordId') ?? '';
    landlordName = prefs.getString('landlordName') ?? '';
    role = prefs.getString('role');
    username = prefs.getString('username');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('sellerId');
    await prefs.remove('buyerPhone');
    await prefs.remove('buyerName');
    await prefs.remove('landlordId');
    await prefs.remove('landlordName');
    await prefs.remove('role');
    await prefs.remove('username');
    token = '';
    sellerId = '';
    buyerPhone = '';
    buyerName = '';
    landlordId = '';
    landlordName = '';
    role = null;
    username = null;
  }
}
*/