import 'package:flutter/material.dart';
import '../models/bargain_model.dart';
import '../services/bargain_service.dart';
import 'bargain_offer_form.dart';

class BargainDetailScreen extends StatefulWidget {
  final String bargainId;
  final List<String> productIds;
  final String buyerPhone;

  const BargainDetailScreen({
    Key? key,
    required this.bargainId,
    required this.productIds,
    required this.buyerPhone,
  }) : super(key: key);

  @override
  _BargainDetailScreenState createState() => _BargainDetailScreenState();
}

class _BargainDetailScreenState extends State<BargainDetailScreen> {
  final BargainService _bargainService = BargainService();
  late Future<Bargain> _futureBargain;
  final Map<String, String> _productImageUrls = {};
  bool _isLoadingImages = false;

  @override
  void initState() {
    super.initState();
    _futureBargain = _loadBargain();
    _fetchProductImages();
  }

  Future<void> _fetchProductImages() async {
    setState(() {
      _isLoadingImages = true;
    });
    for (var id in widget.productIds) {
      if (!_productImageUrls.containsKey(id)) {
        try {
          final productData = await _bargainService.fetchProductById(id);
          final imageUrl = productData['imageUrl'] ?? '';
          _productImageUrls[id] = _buildFullImageUrl(imageUrl);
        } catch (e) {
          _productImageUrls[id] = '';
        }
      }
    }
    setState(() {
      _isLoadingImages = false;
    });
  }

  String _buildFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    // Adjust this base URL as per your backend
    return 'http://172.20.10.2:5000/$imageUrl';
  }

  Future<Bargain> _loadBargain() async {
    try {
      final bargain = await _bargainService.getBargainDetail(widget.bargainId, widget.buyerPhone);
      if (bargain == null) throw Exception('No bargain data received');
      return bargain;
    } catch (e) {
      throw Exception('Failed to load bargain: $e');
    }
  }

  Future<void> _refreshBargain() async {
    final newBargain = await _loadBargain();
    setState(() {
      _futureBargain = Future.value(newBargain);
    });
    await _fetchProductImages();
  }

  Future<void> _submitBuyerOffer(
    String buyerName,
    String buyerPhone,
    List<Map<String, dynamic>> items,
    String note,
  ) async {
    try {
      double calculatedTotalPrice = 0.0;
      for (var item in items) {
        calculatedTotalPrice += (item['quantity'] ?? 0) * (item['price']?.toDouble() ?? 0.0);
      }

      await _bargainService.buyerRespondToBargain(
        bargainId: widget.bargainId,
        action: 'counter',
        items: items,
        totalCounterPrice: calculatedTotalPrice,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer sent successfully')),
      );
      await _refreshBargain();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send offer: $e')),
      );
    }
  }

  Future<void> _acceptSellerOffer(double acceptedPrice) async {
    try {
      await _bargainService.buyerRespondToBargain(
        bargainId: widget.bargainId,
        action: 'accept',
        items: [],
        totalCounterPrice: acceptedPrice,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer accepted')),
      );
      await _refreshBargain();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept offer: $e')),
      );
    }
  }

  Future<void> _rejectSellerOffer() async {
    try {
      await _bargainService.buyerRespondToBargain(
        bargainId: widget.bargainId,
        action: 'reject',
        items: [],
        totalCounterPrice: 0.0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer rejected')),
      );
      await _refreshBargain();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject offer: $e')),
      );
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return 'Unknown time';
    final parsed = time is String ? DateTime.tryParse(time) : time as DateTime?;
    return parsed?.toLocal().toString() ?? 'Unknown time';
  }

  String _formatCurrency(double amount) => '₦${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bargain Details')),
      body: FutureBuilder<Bargain>(
        future: _futureBargain,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoadingImages) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No bargain found'));
          }

          final bargain = snapshot.data!;
          final isAccepted = bargain.status == 'accepted';

          List<Map<String, dynamic>> allOffers = [
            ...?bargain.buyerOffers?.map((e) => {
                  'by': 'You',
                  'price': e.totalOfferedPrice?.toDouble() ?? 0.0,
                  'items': e.items,
                  'time': e.time,
                }),
            ...?bargain.sellerOffers?.map((e) => {
                  'by': 'Seller',
                  'price': e.totalPrice?.toDouble() ?? 0.0,
                  'items': e.items,
                  'time': e.time,
                }),
          ];

          allOffers.sort((a, b) {
            final aTime = DateTime.tryParse(a['time']?.toString() ?? '') ?? DateTime.now();
            final bTime = DateTime.tryParse(b['time']?.toString() ?? '') ?? DateTime.now();
            return bTime.compareTo(aTime);
          });

          double acceptedPrice = bargain.acceptedPrice ?? 0.0;
          if (acceptedPrice <= 0 && allOffers.isNotEmpty) {
            acceptedPrice = allOffers.first['price'] ?? 0.0;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seller: ${bargain.sellerName}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Status: ${bargain.status}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                if (isAccepted) ...[
                  Text('Accepted Bargain Price: ${_formatCurrency(acceptedPrice)}',
                      style: const TextStyle(fontSize: 20, color: Colors.green)),
                  const SizedBox(height: 20),
                  const Text('Bargain has been accepted.'),
                ] else ...[
                  if (bargain.sellerOffers.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _acceptSellerOffer(
                                bargain.sellerOffers.last.totalPrice?.toDouble() ?? 0.0),
                            child: Text(
                                'Accept Seller Offer (${_formatCurrency(bargain.sellerOffers.last.totalPrice?.toDouble() ?? 0.0)})'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _rejectSellerOffer,
                            child: const Text('Reject Seller Offer'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text('Offer History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allOffers.length,
                      itemBuilder: (context, index) {
                        final offer = allOffers[index];
                        final productId = (offer['items'] != null && offer['items'].isNotEmpty)
                            ? offer['items'][0].productId  // Fixed here
                            : null;
                        final imageUrl = (productId != null) ? _productImageUrls[productId] ?? '' : '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                    ),
                                  )
                                : const Icon(Icons.image_not_supported),
                            title: Text('${offer['by']} offered ${_formatCurrency(offer['price'] ?? 0.0)}'),
                            subtitle: Text('Items: ${offer['items']?.length ?? 0}\nTime: ${_formatTime(offer['time'])}'),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                  BargainOfferForm(
                    productIds: widget.productIds,
                    productImageUrls: _productImageUrls,
                    onSubmitOffer: _submitBuyerOffer,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
