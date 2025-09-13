// lib/widgets/bargain_offer_form.dart

import 'package:flutter/material.dart';

typedef OnSubmitOffer = Future<void> Function(
  String buyerName,
  String buyerPhone,
  List<Map<String, dynamic>> items,
  String note,
);

class BargainOfferForm extends StatefulWidget {
  final List<String> productIds;
  final Map<String, String> productImageUrls;
  final OnSubmitOffer onSubmitOffer;
  final void Function(List<Map<String, dynamic>>)? onPreviewItems;

  const BargainOfferForm({
    Key? key,
    required this.productIds,
    required this.productImageUrls,
    required this.onSubmitOffer,
    this.onPreviewItems,
  }) : super(key: key);

  @override
  _BargainOfferFormState createState() => _BargainOfferFormState();
}

class _BargainOfferFormState extends State<BargainOfferForm> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _items = [];
  double _totalOfferedPrice = 0.0;

  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedProductId;

  bool get _canAddItem =>
      _selectedProductId != null &&
      int.tryParse(_quantityController.text) != null &&
      double.tryParse(_priceController.text) != null;

  void _addItem() {
    if (!_formKey.currentState!.validate() || _selectedProductId == null) return;

    final quantity = int.parse(_quantityController.text);
    final price = double.parse(_priceController.text);

    setState(() {
      _items.add({
        'productId': _selectedProductId,
        'quantity': quantity,
        'price': price,
      });
      _totalOfferedPrice += price * quantity;
      _selectedProductId = null;
      _quantityController.text = '1';
      _priceController.clear();
    });

    widget.onPreviewItems?.call(_items);
  }

  Future<void> _submit() async {
    if (_items.isEmpty ||
        _buyerNameController.text.isEmpty ||
        _buyerPhoneController.text.isEmpty ||
        _noteController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Complete all fields')));
      return;
    }

    try {
      await widget.onSubmitOffer(
        _buyerNameController.text.trim(),
        _buyerPhoneController.text.trim(),
        _items,
        _noteController.text.trim(),
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Offer submitted!')));
      setState(() {
        _items.clear();
        _totalOfferedPrice = 0;
        _noteController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildProductImage(String productId) {
    final imageUrl = widget.productImageUrls[productId];

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 32,
        height: 32,
        color: Colors.grey[200],
        child: const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
      );
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _buyerNameController,
              decoration: const InputDecoration(labelText: 'Your Name'),
              validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
            ),
            TextFormField(
              controller: _buyerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              validator: (v) => v == null || v.isEmpty ? 'Phone required' : null,
            ),
            DropdownButtonFormField<String>(
              value: _selectedProductId,
              decoration: const InputDecoration(labelText: 'Select Product'),
              items: widget.productIds.map((productId) {
                final imageUrl = widget.productImageUrls[productId] ?? '';
                return DropdownMenuItem(
                  value: productId,
                  child: SizedBox(
                    width: 250,
                    child: Row(
                      children: [
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              imageUrl,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          )
                        else
                          const Icon(Icons.inventory_2, size: 24, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            productId,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedProductId = v),
              validator: (v) => v == null ? 'Select a product' : null,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _canAddItem ? _addItem : null,
              child: const Text('Add Item'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note to Seller',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        if (_items.isNotEmpty) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              return ListTile(
                leading: _buildProductImage(item['productId']),
                title: Text(item['productId']),
                subtitle: Text("Qty: ${item['quantity']} - ₦${item['price']} each"),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Total Offered: ₦${_totalOfferedPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _items.isNotEmpty ? _submit : null,
          child: const Text('Send Offer'),
        ),
      ]),
    );
  }
}
