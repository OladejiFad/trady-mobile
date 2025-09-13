import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/admin_model.dart';
import '../../global/admin_auth_data.dart';

// Define a classic color palette for elegance
const Color primaryTeal = Color(0xFF004D40);
const Color accentGold = Color(0xFFD4A017);
const Color backgroundGradientStart = Color(0xFFF5F7FA);
const Color backgroundGradientEnd = Color(0xFFE2E8F0);

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({Key? key}) : super(key: key);

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? errorMessage;

  /// Handles form submission for login or registration
  void handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    setState(() => errorMessage = null);

    if (isLogin) {
      final admin = await AdminService.loginAdmin(username, password);
      if (admin == null) {
        setState(() => errorMessage = 'Login failed. Check credentials.');
      } else {
        AdminAuthData.token = admin.token;
        AdminAuthData.adminId = admin.id;
        AdminAuthData.username = admin.username;

        // Save admin auth data persistently
        await AdminAuthData.save();

        print('✅ Admin Token after login: ${AdminAuthData.token}');

        if (AdminAuthData.token.isNotEmpty) {
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        } else {
          setState(() => errorMessage = 'Token missing after login.');
        }
      }
    } else {
      final result = await AdminService.registerAdmin(username, phone, password);
      if (result == null) {
        setState(() {
          isLogin = true;
          errorMessage = 'Registration successful. Please login.';
        });
        usernameController.clear();
        phoneController.clear();
        passwordController.clear();
      } else {
        setState(() => errorMessage = result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLogin ? 'Admin Login' : 'Admin Registration',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Georgia',
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryTeal, Color(0xFF00695C)],
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundGradientStart, backgroundGradientEnd],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: FadeInAnimation(
              duration: const Duration(milliseconds: 800),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF7FAFC)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  padding: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isLogin ? 'Welcome Back' : 'Create Admin Account',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: primaryTeal,
                            fontFamily: 'Georgia',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: usernameController,
                          label: 'Username',
                          icon: Icons.person,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        if (!isLogin) ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: phoneController,
                            label: 'Phone',
                            icon: Icons.phone,
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: passwordController,
                          label: 'Password',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (value) => value != null && value.length >= 8 ? null : 'Min 8 characters',
                        ),
                        const SizedBox(height: 16),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        _buildActionButton(
                          text: isLogin ? 'Login' : 'Register',
                          onPressed: handleSubmit,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() => isLogin = !isLogin),
                          child: Text(
                            isLogin ? "Don't have an account? Register" : "Already registered? Login",
                            style: const TextStyle(
                              color: accentGold,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }

  /// Builds a styled text field with icon and validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: primaryTeal, fontFamily: 'Roboto'),
        filled: true,
        fillColor: Colors.teal.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: primaryTeal),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentGold, width: 2),
        ),
      ),
      style: const TextStyle(fontFamily: 'Roboto', color: Colors.black87),
      validator: validator,
    );
  }

  /// Builds a styled action button for submit
  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return FadeInAnimation(
      duration: const Duration(milliseconds: 1000),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [accentGold, Color(0xFFB8860B)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// FadeInAnimation widget for smooth transitions
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  _FadeInAnimationState createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
