import 'package:flutter/material.dart';
import '../../models/group_buy_model.dart';
import '../../services/group_buy_service.dart';
import '../../screens/buyer/group_buy_payment_screen.dart';  // Import payment screen

class GroupBuyJoinForm extends StatefulWidget {
  final GroupBuy groupBuy;
  final VoidCallback? onSuccess;

  const GroupBuyJoinForm({
    super.key,
    required this.groupBuy,
    this.onSuccess,
  });

  @override
  State<GroupBuyJoinForm> createState() => _GroupBuyJoinFormState();
}

class _GroupBuyJoinFormState extends State<GroupBuyJoinForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final participant = GroupParticipant(name: name, phone: phone, quantity: 1);

    setState(() => _isLoading = true);

    try {
      // 1. Join group buy
      await GroupBuyService().joinGroupBuy(
        groupId: widget.groupBuy.id!,
        participant: participant,
      );

      Navigator.pop(context); // Close join dialog

      // 2. Navigate to payment screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupBuyPaymentScreen(
            groupBuy: widget.groupBuy,
            participantPhone: phone,
            onPaymentSuccess: widget.onSuccess ?? () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Join "${widget.groupBuy.title}"'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Your Name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter your name' : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter phone number' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Join Now'),
        ),
      ],
    );
  }
}
