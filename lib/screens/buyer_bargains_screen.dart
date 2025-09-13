// lib/screens/buyer_bargains_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bargain_model.dart';
import '../services/bargain_service.dart';
import '../utils/image_utils.dart';
import 'send_bargain_screen.dart';
import 'bargain_detail_screen.dart';

class BuyerBargainsScreen extends StatefulWidget {
  final String buyerPhone;

  const BuyerBargainsScreen({Key? key, required this.buyerPhone}) : super(key: key);

  @override
  _BuyerBargainsScreenState createState() => _BuyerBargainsScreenState();
}

class _BuyerBargainsScreenState extends State<BuyerBargainsScreen> {
  late Future<List<Bargain>> _futureBargains;
  final BargainService _bargainService = BargainService();
  final Map<String, String> _productImageUrls = {};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _futureBargains = _fetchBargainsWithImages();
  }

  Future<List<Bargain>> _fetchBargainsWithImages() async {
    final bargains = await _bargainService.getBuyerBargains(widget.buyerPhone);

    for (var bargain in bargains) {
      final productId = _getFirstProductId(bargain);
      if (productId != null && !_productImageUrls.containsKey(productId)) {
        try {
          final product = await _bargainService.fetchProductById(productId);
          final imageUrl = ImageUtils.buildFullImageUrl(product['imageUrl']);
          _productImageUrls[productId] = imageUrl;
        } catch (e) {
          _productImageUrls[productId] = '';
        }
      }
    }

    return bargains;
  }

  String? _getFirstProductId(Bargain bargain) {
    if (bargain.buyerOffers.isNotEmpty) {
      final items = bargain.buyerOffers.last.items;
      if (items != null && items.isNotEmpty) {
        return items.first.productId;
      }
    } else if (bargain.sellerOffers.isNotEmpty) {
      final items = bargain.sellerOffers.last.items;
      if (items != null && items.isNotEmpty) {
        return items.first.productId;
      }
    }
    return null;
  }

  Future<void> _openBargainDetail(Bargain bargain) async {
    final latestBuyerOffer = bargain.buyerOffers.isNotEmpty ? bargain.buyerOffers.last : null;
    final productIds = latestBuyerOffer?.items.map((e) => e.productId.toString()).toList() ?? [];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BargainDetailScreen(
          bargainId: bargain.id,
          productIds: productIds,
          buyerPhone: widget.buyerPhone,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _futureBargains = _fetchBargainsWithImages();
      });
    }
  }

  Future<void> _createNewBargain() async {
    try {
      final productIds = await _bargainService.getAvailableProductIdsForBuyer();

      if (productIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No products available for bargaining.')),
        );
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SendBargainScreen(productIds: productIds),
        ),
      );

      if (result == true) {
        setState(() {
          _futureBargains = _fetchBargainsWithImages();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'My Bargains',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _createNewBargain,
          ),
        ],
      ),
      body: FutureBuilder<List<Bargain>>(
        future: _futureBargains,
        builder: (context, snapshot) {
          if (_isRefreshing || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bargains found.'));
          }

          final bargains = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _isRefreshing = true);
              final refreshed = await _fetchBargainsWithImages();
              setState(() {
                _futureBargains = Future.value(refreshed);
                _isRefreshing = false;
              });
            },
            child: ListView.builder(
              itemCount: bargains.length,
              itemBuilder: (context, index) {
                final bargain = bargains[index];
                final latestBuyerOffer = bargain.buyerOffers.isNotEmpty ? bargain.buyerOffers.last : null;
                final latestSellerOffer = bargain.sellerOffers.isNotEmpty ? bargain.sellerOffers.last : null;
                final productId = _getFirstProductId(bargain);
                final imageUrl = productId != null ? _productImageUrls[productId] ?? '' : '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seller: ${bargain.sellerName}',
                          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                        ),
                        if (bargain.status == 'accepted')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Accepted',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('Status: ${bargain.status}', style: GoogleFonts.lato()),
                        const SizedBox(height: 4),
                        Text(
                          'Your Latest Offer: ₦${latestBuyerOffer?.totalOfferedPrice.toStringAsFixed(2) ?? 'N/A'}',
                          style: GoogleFonts.lato(),
                        ),
                        Text(
                          'Seller Latest Offer: ₦${latestSellerOffer?.totalCounterPrice.toStringAsFixed(2) ?? 'N/A'}',
                          style: GoogleFonts.lato(),
                        ),
                      ],
                    ),
                    trailing: imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                            ),
                          )
                        : const Icon(Icons.image_not_supported, size: 40),
                    onTap: () => _openBargainDetail(bargain),
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
