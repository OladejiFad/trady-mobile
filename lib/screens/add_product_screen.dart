import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String _name = '';
  String _description = '';
  String _category = '';
  double _price = 0;
  int _stock = 0;
  List<XFile> _images = [];
  String? _errorMessage;
  double? _discountPercent;

  bool _isBargainable = false;
  bool _isLoading = false;

  String? _marketSection;

  final List<String> _sizes = [];
  final List<String> _colors = [];

  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();

  final List<String> _categories = [
    'Fashion',
    'Kids Wear',
    'Electronics',
    'Home & Kitchen',
    'Beauty',
    'Sports',
    'Books',
  ];

  final List<DropdownMenuItem<String?>> _marketSectionItems = [
    const DropdownMenuItem(value: null, child: Text('Normal Product')),
    const DropdownMenuItem(value: 'used', child: Text('Used (Market Day)')),
    const DropdownMenuItem(value: 'general', child: Text('General (Market Day)')),
  ];

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select up to 5 images')),
      );
    } else {
      setState(() => _images = picked);
    }
  }

  void _addSize() {
    final val = _sizeController.text.trim();
    if (val.isNotEmpty && !_sizes.contains(val)) {
      setState(() {
        _sizes.add(val);
        _sizeController.clear();
      });
    }
  }

  void _addColor() {
    final val = _colorController.text.trim();
    if (val.isNotEmpty && !_colors.contains(val)) {
      setState(() {
        _colors.add(val);
        _colorController.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear old error
    });

    try {
      await ProductService.createProduct(
        name: _name,
        description: _description,
        category: _category,
        price: _price,
        stock: _stock,
        images: _images,
        isBargainable: _isBargainable,
        marketSection: _marketSection,
        sizes: _sizes,
        colors: _colors,
        discount: _discountPercent ?? 0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error during product submission: $e');

      String errorMessage = 'Failed to add product.';
      try {
        if (e.toString().contains('{')) {
          final start = e.toString().indexOf('{');
          final jsonStr = e.toString().substring(start);
          final decoded = jsonDecode(jsonStr);
          if (decoded['message'] != null) {
            errorMessage = decoded['message'];
          }
        }
      } catch (_) {
        // Ignore JSON parse error
      }

      setState(() {
        _errorMessage = errorMessage;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStyledTextField({
    required String label,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: keyboardType,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildChipsSection({
    required String label,
    required List<String> items,
    required TextEditingController controller,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label (optional)', style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Enter and tap +'),
              ),
            ),
            IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle, color: Colors.green)),
          ],
        ),
        Wrap(
          spacing: 8,
          children: items
              .map((item) => Chip(
                    label: Text(item),
                    onDeleted: () => setState(() => items.remove(item)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStyledTextField(
                        label: 'Product Name',
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => _name = val!.trim(),
                      ),
                      _buildStyledTextField(
                        label: 'Price',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final p = double.tryParse(val);
                          if (p == null || p <= 0) return 'Enter valid positive number';
                          return null;
                        },
                        onSaved: (val) => _price = double.parse(val!),
                      ),
                      _buildStyledTextField(
                        label: 'Discount % (optional)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val == null || val.isEmpty) return null;
                          final percent = double.tryParse(val);
                          if (percent == null || percent <= 0 || percent >= 100) return 'Enter valid % (1-99)';
                          return null;
                        },
                        onSaved: (val) {
                          if (val == null || val.isEmpty) {
                            _discountPercent = 0;
                          } else {
                            _discountPercent = double.parse(val);
                          }
                        },


                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: DropdownButtonFormField<String>(
                          value: _category.isNotEmpty ? _category : null,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _categories
                              .map((cat) => DropdownMenuItem<String>(
                                    value: cat,
                                    child: Text(cat),
                                  ))
                              .toList(),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          onChanged: (val) => setState(() => _category = val!),
                          onSaved: (val) => _category = val!,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: 'Market Section (optional)',
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _marketSectionItems,
                          value: _marketSection,
                          onChanged: (val) => setState(() => _marketSection = val),
                          onSaved: (val) => _marketSection = val,
                        ),
                      ),
                      _buildStyledTextField(
                        label: 'Stock',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final s = int.tryParse(val);
                          if (s == null || s < 0) return 'Enter valid stock count';
                          return null;
                        },
                        onSaved: (val) => _stock = int.parse(val!),
                      ),
                      _buildChipsSection(
                        label: 'Sizes',
                        items: _sizes,
                        controller: _sizeController,
                        onAdd: _addSize,
                      ),
                      _buildChipsSection(
                        label: 'Colors',
                        items: _colors,
                        controller: _colorController,
                        onAdd: _addColor,
                      ),
                      _buildStyledTextField(
                        label: 'Description',
                        maxLines: 4,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => _description = val!.trim(),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _isBargainable,
                            onChanged: (val) => setState(() => _isBargainable = val ?? false),
                          ),
                          const Text('Allow Bargaining on this product'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Images (max 5)'),
                      ),
                      const SizedBox(height: 10),
                      if (_images.isNotEmpty)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _images.map((img) {
                            if (kIsWeb) {
                              return FutureBuilder<Uint8List>(
                                future: img.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(snapshot.data!, width: 100, height: 100, fit: BoxFit.cover),
                                    );
                                  } else {
                                    return const SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    );
                                  }
                                },
                              );
                            } else {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(img.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                          }).toList(),
                        ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Add Product', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}