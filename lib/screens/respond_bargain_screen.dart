// lib/screens/respond_bargain_screen.dart

import 'package:flutter/material.dart';
import '../models/bargain_model.dart';
import '../services/bargain_service.dart';
import '../utils/image_utils.dart';

class RespondBargainScreen extends StatefulWidget {
  final Bargain bargain;
  final BargainService bargainService;

  const RespondBargainScreen({
    Key? key,
    required this.bargain,
    required this.bargainService,
  }) : super(key: key);

  @override
  _RespondBargainScreenState createState() => _RespondBargainScreenState();
}

class _RespondBargainScreenState extends State<RespondBargainScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _originalBuyerItems = [];
  List<TextEditingController> _priceControllers = [];
  double _originalBuyerTotal = 0.0;
  String? _buyerNote;
  final Map<String, String> _productImageUrls = {};

  @override
  void initState() {
    super.initState();
    _initializeItemsFromBuyerOffer();
  }

  Future<void> _initializeItemsFromBuyerOffer() async {
    _originalBuyerTotal = 0.0;

    if (widget.bargain.buyerOffers.isNotEmpty) {
      final lastBuyerOffer = widget.bargain.buyerOffers.last;
      final totalOfferedPrice = lastBuyerOffer.totalOfferedPrice ?? 0;
      final items = lastBuyerOffer.items;
      final totalQuantity = items.fold<int>(0, (sum, item) => sum + (item.quantity ?? 1));
      final unitPrice = totalQuantity > 0 ? totalOfferedPrice / totalQuantity : 0;

      _buyerNote = lastBuyerOffer.note;
      _originalBuyerItems = [];

      for (var item in items) {
        final quantity = item.quantity ?? 1;
        String imageUrl = item.imageUrl ?? '';

        if (imageUrl.isEmpty && item.productId.isNotEmpty) {
          try {
            final product = await widget.bargainService.fetchProductById(item.productId);
            imageUrl = ImageUtils.buildFullImageUrl(product['imageUrl']);
          } catch (_) {
            imageUrl = '';
          }
        } else {
          imageUrl = ImageUtils.buildFullImageUrl(imageUrl);
        }

        _productImageUrls[item.productId] = imageUrl;

        _originalBuyerItems.add({
          'productId': item.productId,
          'productName': item.productName,
          'imageUrl': imageUrl,
          'quantity': quantity,
          'price': unitPrice,
        });
      }

      _originalBuyerTotal = _originalBuyerItems.fold(
        0.0,
        (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int),
      );

      _items = _originalBuyerItems.map((item) => Map<String, dynamic>.from(item)).toList();
      _priceControllers = _items
          .map((item) => TextEditingController(text: (item['price'] as double).toStringAsFixed(2)))
          .toList();

      setState(() {});
    }
  }

  @override
  void dispose() {
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updatePrice(int index) {
    final text = _priceControllers[index].text;
    final parsedPrice = double.tryParse(text);
    if (parsedPrice == null || parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price greater than zero')),
      );
      return;
    }

    setState(() {
      _items[index]['price'] = parsedPrice;
      _priceControllers[index].text = parsedPrice.toStringAsFixed(2);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated ₦${parsedPrice.toStringAsFixed(2)} for ${_items[index]['productName']}')),
    );
  }

  Future<void> _submitResponse(String action) async {
    if (action == 'counter') {
      final valid = _items.every((item) =>
          item['price'] != null &&
          item['price'] is double &&
          (item['price'] as double) > 0 &&
          item['quantity'] != null &&
          (item['quantity'] is int || item['quantity'] is double) &&
          (item['quantity'] as num) > 0);
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All prices and quantities must be valid and greater than zero')),
        );
        return;
      }
    }

    List<Map<String, dynamic>>? itemsToSend;
    double? totalPriceToSend;

    if (action == 'accept') {
      itemsToSend = _originalBuyerItems;
      totalPriceToSend = _originalBuyerTotal;
    } else if (action == 'counter') {
      itemsToSend = _items;
      totalPriceToSend = _items.fold<double>(
        0.0,
        (sum, item) => sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 0)),
      );
    }

    try {
      await widget.bargainService.respondToBargain(
        bargainId: widget.bargain.id,
        action: action,
        items: action == 'reject' ? null : itemsToSend,
        totalCounterPrice: action == 'reject' ? null : totalPriceToSend,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bargain $action sent')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTotal = _originalBuyerTotal.toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(title: const Text('Respond to Bargain')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_buyerNote != null && _buyerNote!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, color: Colors.brown),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_buyerNote!)),
                  ],
                ),
              ),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('No items to respond to.'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final imageUrl = _productImageUrls[item['productId']] ?? '';

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image, size: 80),
                                        )
                                      : Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image_not_supported),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['productName'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Qty: ${item['quantity']}'),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _priceControllers[index],
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(
                                                labelText: 'Price (₦)',
                                                isDense: true,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _updatePrice(index),
                                            child: const Text('Update'),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Buyer offered: ₦$formattedTotal',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submitResponse('accept'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text('Accept ₦$formattedTotal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submitResponse('reject'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submitResponse('counter'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Counter Offer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
