import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/store_model.dart';
import '../../models/promo_model.dart';
import '../../services/promo_service.dart';
import '../../widgets/store/store_profile_card.dart';
import '../../services/cart_service.dart';
import '../../screens/cart_screen.dart';


class StoreDetailScreen extends StatefulWidget {
  final Store store;
  const StoreDetailScreen({Key? key, required this.store}) : super(key: key);

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final CartService cartService = CartService();

  List<Promo> sellerPromos = [];
  bool isLoading = true;
  int cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPromos();
    Future.delayed(Duration.zero, () {
      setState(() {
        cartCount = cartService.localCart.length;
      });
    });
  }

  Future<void> _loadPromos() async {
    try {
      final promos = await PromoService.fetchSellerPromos(widget.store.sellerId);
      setState(() {
        sellerPromos = promos.where((p) => p.isActive).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load promos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.store.storeName.isNotEmpty ? widget.store.storeName : "No Name",
          style: GoogleFonts.cinzel(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF1A2E6B),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(cartService: cartService),
                    ),
                  );
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/trady_logo.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.5)],
                ),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedOpacity(
                            opacity: isLoading ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: IgnorePointer(
                                ignoring: true,
                                child: StoreProfileCard(
                                  store: widget.store,
                                  promos: sellerPromos,
                                  // height removed to avoid overflow
                                  onEnterPressed: null, // no longer needed
                                ),
                              ),
                            ),
                          ),
                          if (sellerPromos.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.deepPurple.shade200,
                                      const Color(0xFFD4A017).withOpacity(0.2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD4A017), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: sellerPromos.map((promo) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        '🎁 ${promo.code} → ${promo.discountType == 'percentage' ? '${promo.discountValue.toInt()}% OFF' : '₦${promo.discountValue} OFF'}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
