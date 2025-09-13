import 'package:flutter/material.dart';
import '../../global/auth_data.dart';
import '../../screens/buyer/buyer_chat_screen.dart'; // Correct import path

class BuyerInfoForm extends StatefulWidget {
  final String landlordId;
  final String landlordName;
  final String propertyId;

  const BuyerInfoForm({
    Key? key,
    required this.landlordId,
    required this.landlordName,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<BuyerInfoForm> createState() => _BuyerInfoFormState();
}

class _BuyerInfoFormState extends State<BuyerInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🧪 Logging for debugging
    print("🧪 BuyerInfoForm launched with propertyId: ${widget.propertyId}");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // ✅ Set global identity for guest buyer
      AuthData.buyerName = name;
      AuthData.buyerPhone = phone;

      Navigator.of(context).pop(); // Close the form

      // ✅ Navigate to BuyerChatScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuyerChatScreen(
            landlordId: widget.landlordId,
            landlordName: widget.landlordName,
            propertyId: widget.propertyId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Chat with ${widget.landlordName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Your Name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter your name' : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Your Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter your phone number' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Start Chat'),
        ),
      ],
    );
  }
}
