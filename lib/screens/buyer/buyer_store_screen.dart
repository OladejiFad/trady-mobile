import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/store_model.dart';
import '../../services/store_service.dart';
import '../../services/product_service.dart';
import '../../widgets/store/store_profile_card.dart';
import 'store_category_screen.dart';
import '../../models/promo_model.dart';
import '../../services/promo_service.dart';


class BuyerStoreScreen extends StatefulWidget {
  const BuyerStoreScreen({Key? key}) : super(key: key);

  @override
  State<BuyerStoreScreen> createState() => _BuyerStoreScreenState();
}

class _BuyerStoreScreenState extends State<BuyerStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final storeService = StoreService();
  bool isLoading = true;

  Map<String, List<Store>> stores = {
    'vendor stores': [],
    'skill workers': [],
    'top sellers store': [],
    'ballers league': [],
  };

  Map<String, List<Promo>> _sellerPromosMap = {};


  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
  try {
    final handworkStores = await storeService.fetchSkillWorkerStores();
    final vendorStores = await storeService.fetchVendorStores();

    stores['vendor stores'] = vendorStores;
    stores['skill workers'] = handworkStores;

    final topSellerIds = await ProductService.fetchTopSellers();
    final allStores = [...vendorStores, ...handworkStores]; // 🔥 Combine both
    stores['top sellers store'] = allStores
        .where((store) => topSellerIds.contains(store.sellerId))
        .toList();

    stores['ballers league'] = [];

    for (final store in vendorStores) {
      try {
        final promos = await PromoService.fetchSellerPromos(store.sellerId);
        _sellerPromosMap[store.sellerId] = promos;
      } catch (_) {
        _sellerPromosMap[store.sellerId] = [];
      }
    }

    setState(() => isLoading = false);
  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load stores: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          title: Text(
            'BuyNest Stores',
            style: GoogleFonts.cinzel(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF1A2E6B),
          foregroundColor: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(0.5),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildCard(
                            title: 'Skill Workers',
                            imagePath: 'assets/work.png',
                            buttonText: 'Hire skill workers',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StoreCategoryScreen(
                                    title: 'Skill Workers',
                                    stores: stores['skill workers'] ?? [],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCard(
                            title: 'Vendor Stores',
                            imagePath: 'assets/store.png',
                            buttonText: 'Check out vender stores',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StoreCategoryScreen(
                                    title: 'vendor stores',
                                    stores: stores['vendor stores'] ?? [],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildCard(
                            title: 'Top Sellers',
                            imagePath: 'assets/award.png',
                            buttonText: 'Buy from top sellers',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StoreCategoryScreen(
                                    title: 'Top Sellers Store',
                                    stores: stores['top sellers store'] ?? [],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCard(
                            title: 'Ballers League',
                            imagePath: 'assets/ballers.png',
                            buttonText: 'Enter baller stores',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StoreCategoryScreen(
                                    title: 'Ballers League',
                                    stores: stores['ballers league'] ?? [],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 768) return 3;
    if (width >= 480) return 2;
    return 1;
  }

  Widget _buildCard({
    required String title,
    String? subtitle,
    String? imagePath,
    IconData? icon,
    required String buttonText,
    required VoidCallback onTap,
    double imageHeight = 90,
    double imageWidth = 90,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 6 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF1A2E6B)
                : const Color(0xFFD4A017),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      imagePath!,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A0C2A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFD4A017)),
                          ),
                          elevation: 2,
                          textStyle: GoogleFonts.cinzel(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(buttonText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
