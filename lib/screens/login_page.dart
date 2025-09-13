import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../services/auth_service.dart';
import '../global/auth_data.dart';
import '../main.dart';

const Color coral = Color(0xFFFF7F50);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  void handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final result = await loginUser(
        phone: phoneCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      final user = result['user'];

      final token = result['token'] ?? '';
      if (token.isEmpty) throw Exception('Token missing in response');

      Map<String, dynamic> payload = Jwt.parseJwt(token);
      final role = payload['role'] ?? '';

      final isApproved = user['isApprovedSeller'] ?? false;
      if (role == 'seller' && !isApproved) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              'Pending Verification',
              style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Please wait for admin approval.',
              style: TextStyle(color: Colors.grey.shade800),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.teal.shade600),
                ),
              ),
            ],
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);
      await prefs.setString('userRole', role);
      await prefs.setString('buyerPhone', user['phone'] ?? '');
      if (role == 'seller') {
        await prefs.setString('sellerId', user['id']);
        await prefs.remove('landlordId');
      } else if (role == 'landlord') {
        await prefs.setString('landlordId', user['id']);
        await prefs.remove('sellerId');
      } else {
        await prefs.remove('sellerId');
        await prefs.remove('landlordId');
      }

      AuthData.token = token;
      AuthData.buyerPhone = user['phone'] ?? '';
      AuthData.buyerName = user['name'] ?? '';
      AuthData.sellerId = role == 'seller' ? user['id'] : '';
      AuthData.landlordId = role == 'landlord' ? user['id'] : '';
      AuthData.landlordName = role == 'landlord' ? user['name'] ?? '' : '';

      String dashboardRoute;
      if (role == 'seller') {
        dashboardRoute = Routes.dashboard;
      } else if (role == 'landlord') {
        dashboardRoute = Routes.landlordDashboard;
      } else {
        dashboardRoute = Routes.home;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Success',
            style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Login successful! Welcome, ${user['name']}',
            style: TextStyle(color: Colors.grey.shade800),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, dashboardRoute);
              },
              child: Text(
                'OK',
                style: TextStyle(color: Colors.teal.shade600),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Error',
            style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Login failed: $e',
            style: TextStyle(color: Colors.grey.shade800),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.teal.shade600),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal.shade700, Colors.teal.shade500],
            ),
          ),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          labelStyle: TextStyle(color: Colors.teal.shade800),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.phone, color: Colors.teal.shade600),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: Colors.grey.shade800),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordCtrl,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.teal.shade800),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.teal.shade600),
                        ),
                        obscureText: true,
                        style: TextStyle(color: Colors.grey.shade800),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Password is required' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade700, Colors.amber.shade500],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, Routes.register);
                          },
                          child: Text(
                            "Don't have an account? Register",
                            style: TextStyle(
                              fontSize: 14,
                              color: coral,
                              decoration: TextDecoration.underline,
                              decorationColor: coral,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}