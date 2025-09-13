import 'package:flutter/material.dart';
import '../services/bargain_service.dart';
import 'bargain_offer_form.dart';
import '../main.dart';
import '../utils/image_utils.dart';
import '../global/auth_data.dart';

class SendBargainScreen extends StatefulWidget {
  final List<String> productIds;
  final String? bargainId;

  const SendBargainScreen({
    Key? key,
    required this.productIds,
    this.bargainId,
  }) : super(key: key);

  @override
  _SendBargainScreenState createState() => _SendBargainScreenState();
}

class _SendBargainScreenState extends State<SendBargainScreen> {
  final BargainService _bargainService = BargainService();

  Map<String, dynamic>? _firstItem;
  Map<String, String> _productImageUrls = {};

  void _onPreviewItems(List<Map<String, dynamic>> items) {
    setState(() {
      _firstItem = items.isNotEmpty ? items.first : null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductImages();
    });
  }

  Future<void> _loadProductImages() async {
    Map<String, String> imageMap = {};

    for (final id in widget.productIds) {
      try {
        final product = await _bargainService.fetchProductById(id);
        print('🖼️ Product from API: $product');
        final imageUrl = ImageUtils.buildFullImageUrl(product['imageUrl']);

        imageMap[id] = imageUrl;
      } catch (e) {
        imageMap[id] = '';
      }
    }

    if (mounted) {
      setState(() {
        _productImageUrls = imageMap;
      });
    }
  }

  Future<void> _handleSubmitOffer(
    String buyerName,
    String buyerPhone,
    List<Map<String, dynamic>> items,
    String note,
  ) async {
    double totalOfferedPrice = 0;
    for (var item in items) {
      totalOfferedPrice += (item['price'] ?? 0) * (item['quantity'] ?? 0);
    }

    try {
      if (widget.bargainId != null) {
        await _bargainService.buyerRespondToBargain(
          bargainId: widget.bargainId!,
          action: 'counter',
          items: items.map((item) {
            return {
              'productId': item['productId'],
              'quantity': item['quantity'],
              'price': item['price'],
            };
          }).toList(),
          totalCounterPrice: totalOfferedPrice,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Counter offer sent for ₦${totalOfferedPrice.toStringAsFixed(2)}')),
        );
      } else {
        AuthData.buyerPhone = buyerPhone;

        await _bargainService.startOrContinueBargain(
          items: items.map((item) {
            return {
              'productId': item['productId'],
              'quantity': item['quantity'],
              'price': item['price'],
            };
          }).toList(),
          totalOfferedPrice: totalOfferedPrice,
          buyerName: buyerName,
          buyerPhone: buyerPhone,
          note: note.trim().isNotEmpty ? note.trim() : 'No note provided',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bargain started for ₦${totalOfferedPrice.toStringAsFixed(2)}')),
        );
      }

      Navigator.pushReplacementNamed(
        context,
        Routes.buyerBargains,
        arguments: {'buyerPhone': buyerPhone},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildPreviewImage() {
    if (_firstItem == null || _firstItem!['productId'] == null) return const SizedBox.shrink();
    final productId = _firstItem!['productId'];
    final imageUrl = _productImageUrls[productId];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
              ),
            )
          : const Icon(Icons.image_not_supported, size: 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bargainId != null ? 'Counter Seller Offer' : 'Send Bargain Offer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPreviewImage(),
            BargainOfferForm(
              productIds: widget.productIds,
              productImageUrls: _productImageUrls,
              onSubmitOffer: _handleSubmitOffer,
              onPreviewItems: _onPreviewItems,
            ),
          ],
        ),
      ),
    );
  }
}
