import 'package:flutter/material.dart';
import '../models/bargain_model.dart';
import '../services/bargain_service.dart';
import 'respond_bargain_screen.dart';
import '../utils/image_utils.dart';

class SellerBargainsScreen extends StatefulWidget {
  final String sellerAuthToken;

  const SellerBargainsScreen({Key? key, required this.sellerAuthToken}) : super(key: key);

  @override
  _SellerBargainsScreenState createState() => _SellerBargainsScreenState();
}

class _SellerBargainsScreenState extends State<SellerBargainsScreen> {
  late Future<List<Bargain>> _futureBargains;
  late BargainService _bargainService;
  bool _isRefreshing = false;
  final Map<String, String> _productImageUrls = {};

  @override
  void initState() {
    super.initState();
    _bargainService = BargainService(sellerAuthToken: widget.sellerAuthToken);
    _futureBargains = _loadBargainsWithImages();
  }

  Future<List<Bargain>> _loadBargainsWithImages() async {
    final bargains = await _bargainService.getSellerBargains();

    for (var bargain in bargains) {
      final firstProductId = _getFirstProductId(bargain);
      if (firstProductId != null && !_productImageUrls.containsKey(firstProductId)) {
        try {
          final product = await _bargainService.fetchProductById(firstProductId);
          final imageUrl = ImageUtils.buildFullImageUrl(product['imageUrl']);
          _productImageUrls[firstProductId] = imageUrl;
        } catch (e) {
          _productImageUrls[firstProductId] = '';
        }
      }
    }

    return bargains;
  }

  String? _getFirstProductId(Bargain bargain) {
    if (bargain.buyerOffers.isNotEmpty) {
      final offers = bargain.buyerOffers.last.items;
      if (offers != null && offers.isNotEmpty) {
        return offers.first.productId;
      }
    } else if (bargain.sellerOffers.isNotEmpty) {
      final offers = bargain.sellerOffers.last.items;
      if (offers != null && offers.isNotEmpty) {
        return offers.first.productId;
      }
    }
    return null;
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      final updatedBargains = await _loadBargainsWithImages();
      setState(() {
        _futureBargains = Future.value(updatedBargains);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh bargains: $e')),
      );
    }
    setState(() => _isRefreshing = false);
  }

  double _getLastOfferPrice(Bargain bargain) {
    final buyerLastOffer = bargain.buyerOffers.isNotEmpty ? bargain.buyerOffers.last : null;
    final sellerLastOffer = bargain.sellerOffers.isNotEmpty ? bargain.sellerOffers.last : null;

    if (buyerLastOffer == null && sellerLastOffer == null) return 0.0;
    if (buyerLastOffer == null) return sellerLastOffer!.totalPrice?.toDouble() ?? 0.0;
    if (sellerLastOffer == null) return buyerLastOffer.totalOfferedPrice?.toDouble() ?? 0.0;

    final buyerTime = buyerLastOffer.time;
    final sellerTime = sellerLastOffer.time;

    if (buyerTime != null && sellerTime != null) {
      return buyerTime.isAfter(sellerTime)
          ? buyerLastOffer.totalOfferedPrice?.toDouble() ?? 0.0
          : sellerLastOffer.totalPrice?.toDouble() ?? 0.0;
    }

    return (buyerLastOffer.totalOfferedPrice ?? 0) > (sellerLastOffer.totalPrice ?? 0)
        ? buyerLastOffer.totalOfferedPrice!.toDouble()
        : (sellerLastOffer.totalPrice?.toDouble() ?? 0.0);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade700;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text('Seller Bargains'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh bargains',
            onPressed: _refresh,
          ),
        ],
      ),

      body: FutureBuilder<List<Bargain>>(
        future: _futureBargains,
        builder: (context, snapshot) {
          if (_isRefreshing || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No bargains found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final bargains = snapshot.data!;

          return RefreshIndicator(
            color: Colors.deepPurple,
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: bargains.length,
              itemBuilder: (context, index) {
                final bargain = bargains[index];
                final lastOfferPrice = _getLastOfferPrice(bargain);
                final firstProductId = _getFirstProductId(bargain);
                final imageUrl = firstProductId != null ? _productImageUrls[firstProductId] ?? '' : '';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                    ),
                    title: const Text(
                      'Bargain with Buyer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                            decoration: BoxDecoration(
                              color: _statusColor(bargain.status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Status: ${bargain.status[0].toUpperCase()}${bargain.status.substring(1)}',
                              style: TextStyle(
                                color: _statusColor(bargain.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bargain.status.toLowerCase() == 'accepted'
                                ? 'Accepted Price: ₦${lastOfferPrice.toStringAsFixed(2)}'
                                : 'Latest Offer: ₦${lastOfferPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: bargain.status.toLowerCase() == 'accepted' ? Colors.green.shade700 : Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: bargain.status.toLowerCase() == 'pending'
                        ? IconButton(
                            icon: const Icon(Icons.reply, color: Colors.deepPurple),
                            tooltip: 'Respond to bargain',
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RespondBargainScreen(
                                    bargain: bargain,
                                    bargainService: _bargainService,
                                  ),
                                ),
                              );
                              await _refresh();
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
