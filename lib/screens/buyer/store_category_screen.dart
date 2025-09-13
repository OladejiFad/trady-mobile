import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/store_model.dart';
import '../../models/promo_model.dart';
import '../../services/promo_service.dart';
import '../../widgets/store/store_profile_card.dart';
import '../../screens/buyer_product_list_screen.dart'; // ✅ correct import

class StoreCategoryScreen extends StatefulWidget {
  final String title;
  final List<Store> stores;

  const StoreCategoryScreen({
    Key? key,
    required this.title,
    required this.stores,
  }) : super(key: key);

  @override
  State<StoreCategoryScreen> createState() => _StoreCategoryScreenState();
}

class _StoreCategoryScreenState extends State<StoreCategoryScreen> {
  final Map<String, List<Promo>> _sellerPromosMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    for (final store in widget.stores) {
      try {
        final promos = await PromoService.fetchSellerPromos(store.sellerId);
        _sellerPromosMap[store.sellerId] = promos;
      } catch (_) {
        _sellerPromosMap[store.sellerId] = [];
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  int _calculateCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 768) return 3;
    if (width >= 480) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _calculateCrossAxisCount(MediaQuery.of(context).size.width);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.cinzel(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A2E6B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : widget.stores.isEmpty
                ? Center(
                    child: Text(
                      'No stores found',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    itemCount: widget.stores.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final store = widget.stores[index];
                      final promos = _sellerPromosMap[store.sellerId] ?? [];

                      return StoreProfileCard(
                        store: store,
                        promos: promos,
                        onEnterPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BuyerProductListScreen(sellerId: store.sellerId),
                            ),
                          );

                        },
                      );
                    },
                  ),
      ),
    );
  }
}
