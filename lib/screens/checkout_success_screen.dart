import 'buyer/buyer_orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optionally pass promo info from checkout page.
class CheckoutSuccessScreen extends StatefulWidget {
  final String? promoCode;
  final double? discountAmount;

  const CheckoutSuccessScreen({super.key, this.promoCode, this.discountAmount});

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen> {
  String? buyerName;

  @override
  void initState() {
    super.initState();
    _loadBuyerName();

    // Navigate to BuyerOrdersScreen after a 3 second delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BuyerOrdersScreen()),
      );
    });
  }

  Future<void> _loadBuyerName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('buyerName') ?? 'Customer'; // Fallback
    setState(() {
      buyerName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasPromo = widget.promoCode != null && widget.discountAmount != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              Text(
                '🎉 Thank you, ${buyerName ?? ''}, for your order!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your cart has been synced and your order is being processed.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (hasPromo) ...[
                const SizedBox(height: 24),
                Text(
                  'Promo Applied: ${widget.promoCode!}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepOrange,
                  ),
                ),
                Text(
                  'Discount: ₦${widget.discountAmount!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
