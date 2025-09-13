import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';

const Color coral = Color(0xFFFF7F50);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final bvnCtrl = TextEditingController();
  final ninCtrl = TextEditingController();
  final passportCtrl = TextEditingController();
  final occupationCtrl = TextEditingController();
  final idCardCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  String location = 'Lagos';
  String role = 'seller'; // default role

  Widget buildTextField({
  required TextEditingController controller,
  required String label,
  required String? Function(String?)? validator,
  bool obscureText = false,
  TextInputType? keyboardType,
  IconData? prefixIcon,
  bool optional = false,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label + (optional ? ' (optional)' : ''),
      labelStyle: TextStyle(color: Colors.teal.shade800),
      filled: true,
      fillColor: Colors.teal.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.teal.shade600) : null,
    ),
    validator: validator,
    style: TextStyle(color: Colors.grey.shade800),
  );
}

void _showError(String message) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Error',
        style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
      ),
      content: Text(
        message,
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


void handleRegister() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    String message;

    if (role == 'seller') {
      // Require either NIN or ID Card
      if (ninCtrl.text.trim().isEmpty && idCardCtrl.text.trim().isEmpty) {
        _showError('Either NIN or ID Card is required');
        return;
      }

      message = await registerSeller(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
        location: location,
        occupation: 'Skill Workers',         
        jobType: occupationCtrl.text.trim(),
        nin: ninCtrl.text.trim(),
      );
    } else {
      message = await registerLandlord(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
        location: location,
        bvn: bvnCtrl.text.trim(),
        nin: ninCtrl.text.trim(),
        internationalPassport: passportCtrl.text.trim(),
      );
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
          message,
          style: TextStyle(color: Colors.grey.shade800),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
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
          'Error: $e',
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
void initState() {
  super.initState();
}

 

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    bvnCtrl.dispose();
    ninCtrl.dispose();
    passportCtrl.dispose();
    idCardCtrl.dispose();
    occupationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Register',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create Your Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: InputDecoration(
                          labelText: 'Register as',
                          labelStyle: TextStyle(color: Colors.teal.shade800),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.person, color: Colors.teal.shade600),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'seller', child: Text('Seller')),
                          DropdownMenuItem(value: 'landlord', child: Text('Landlord')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            role = val!;
                            if (role == 'seller') {
                              // Clear landlord-only fields
                              bvnCtrl.clear();
                              passportCtrl.clear();
                            } else {
                              // Clear seller-only fields
                              occupationCtrl.clear();
                              idCardCtrl.clear();
                             
                            }
                          });
                          _formKey.currentState?.validate();
                        },
                        style: TextStyle(color: Colors.grey.shade800),
                      ),

                      const SizedBox(height: 16),
                      buildTextField(
                        controller: nameCtrl,
                        label: 'Name',
                        validator: (v) => v == null || v.isEmpty ? 'Please enter name' : null,
                        prefixIcon: Icons.account_circle,
                      ),

                      const SizedBox(height: 16),
                      buildTextField(
                        controller: phoneCtrl,
                        label: 'Phone',
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter phone';
                          final regex = RegExp(r'^\+234[789]\d{9}$');
                          if (!regex.hasMatch(v)) return 'Enter valid Nigerian phone +234...';
                          return null;
                        },
                        prefixIcon: Icons.phone,
                      ),

                      const SizedBox(height: 16),
                      buildTextField(
                        controller: passwordCtrl,
                        label: 'Password',
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.length < 8) return 'Password must be at least 8 characters';
                          return null;
                        },
                        prefixIcon: Icons.lock,
                      ),

                      const SizedBox(height: 16),
                      DropdownButtonFormField(
                        value: location,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          labelStyle: TextStyle(color: Colors.teal.shade800),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.location_on, color: Colors.teal.shade600),
                        ),
                        items: ['Lagos', 'Ibadan']
                            .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                            .toList(),
                        onChanged: (val) => setState(() => location = val!),
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      //START
                      if (role == 'seller') ...[
                        buildTextField(
                          controller: occupationCtrl,
                          label: 'Occupation',
                          validator: (v) => v == null || v.isEmpty ? 'Please enter occupation' : null,
                          prefixIcon: Icons.work,
                        ),

                        const SizedBox(height: 16),

                      
                        buildTextField(
                          controller: idCardCtrl,
                          label: 'ID Card (optional if NIN provided)',
                          validator: (v) {
                            if ((v == null || v.isEmpty) && ninCtrl.text.trim().isEmpty) {
                              return 'Either ID Card or NIN is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        buildTextField(
                          controller: ninCtrl,
                          label: 'NIN (optional if ID Card provided)',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if ((v == null || v.isEmpty) && idCardCtrl.text.trim().isEmpty) {
                              return 'Either NIN or ID Card is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],


                      //END

                      
                      if (role == 'landlord') ...[
                        const SizedBox(height: 16),
                        buildTextField(
                          controller: bvnCtrl,
                          label: 'BVN',
                          validator: (v) => v == null || v.isEmpty ? 'BVN is required' : null,
                          prefixIcon: Icons.credit_card,
                        ),
                        const SizedBox(height: 16),

                        buildTextField(
                          controller: ninCtrl,
                          label: 'NIN (optional if passport provided)',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if ((v == null || v.isEmpty) && (passportCtrl.text.trim().isEmpty)) {
                              return 'Either NIN or International Passport is required';
                            }
                            return null;
                          },
                          prefixIcon: FontAwesomeIcons.idCard,
                        ),
                        const SizedBox(height: 16),
                        buildTextField(
                          controller: passportCtrl,
                          label: 'International Passport (optional if NIN provided)',
                          validator: (v) {
                            if ((v == null || v.isEmpty) && (ninCtrl.text.trim().isEmpty)) {
                              return 'Either International Passport or NIN is required';
                            }
                            return null;
                          },
                          prefixIcon: FontAwesomeIcons.passport,
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade700, Colors.amber.shade500],
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
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          child: Text(
                            'Register',
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
                            Navigator.pushNamed(context, '/login');
                          },
                          child: Text(
                            'Already have an account? Login',
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