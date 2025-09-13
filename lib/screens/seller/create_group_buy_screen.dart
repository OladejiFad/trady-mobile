import 'package:flutter/material.dart';
import '../../services/group_buy_service.dart';
import '../../global/auth_data.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class CreateGroupBuyScreen extends StatefulWidget {
  const CreateGroupBuyScreen({super.key});

  @override
  State<CreateGroupBuyScreen> createState() => _CreateGroupBuyScreenState();
}

class _CreateGroupBuyScreenState extends State<CreateGroupBuyScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final minParticipantsController = TextEditingController();
  final descriptionController = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedProductId;

  late Future<List<Product>> _sellerProductsFuture;

  @override
  void initState() {
    super.initState();
    _sellerProductsFuture = ProductService.fetchProductsBySeller(AuthData.sellerId);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await GroupBuyService().createGroupBuy(
        productId: _selectedProductId!,
        title: titleController.text.trim(),
        pricePerUnit: double.parse(priceController.text.trim()),
        minParticipants: int.parse(minParticipantsController.text.trim()),
        deadline: DateTime.now().add(const Duration(days: 60)), // Example deadline
        description: descriptionController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group buy created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group Buy')),
      body: FutureBuilder<List<Product>>(
        future: _sellerProductsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading products: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    items: products.map((product) {
                      return DropdownMenuItem(
                        value: product.id,
                        child: Text(product.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedProductId = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null ? 'Please select a product' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Group Buy Title'),
                    validator: (value) => value!.isEmpty ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price Per Unit (₦)'),
                    validator: (value) => value!.isEmpty ? 'Enter price' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: minParticipantsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min Participants'),
                    validator: (value) => value!.isEmpty ? 'Enter number of participants' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value!.isEmpty ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: const Icon(Icons.group_add),
                    label: _isSubmitting
                        ? const Text('Submitting...')
                        : const Text('Create Group Buy'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
