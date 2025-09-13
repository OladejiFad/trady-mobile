import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import 'checkout_success_screen.dart';
import '../../services/promo_service.dart';
import '../../utils/image_utils.dart'; // ✅ Image URL fixer

class CartScreen extends StatefulWidget {
  final CartService cartService;

  const CartScreen({Key? key, required this.cartService}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> cartItems;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  String? appliedPromoCode;
  double discountAmount = 0.0;

  final _currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦');

  @override
  void initState() {
    super.initState();
    cartItems = widget.cartService.localCart;
  }

  void removeItem(String productId, {bool isBargain = false}) {
    widget.cartService.removeItem(productId, isBargain: isBargain);
    setState(() {
      cartItems = widget.cartService.localCart;
    });
  }

  double get totalAmountWithoutDiscount =>
      cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);

  double get totalAmount => totalAmountWithoutDiscount - discountAmount;

void syncCart() async {
  final phone = _phoneController.text.trim();

  if (phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter phone number')),
    );
    return;
  }

  try {
    // ✅ New unified sync method
    await widget.cartService.syncCartAndLoad(phone);

    setState(() {
      cartItems = widget.cartService.localCart;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cart synced successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to sync cart: $e')),
    );
  }
}



  void placeOrder() async {
  final name = _nameController.text.trim();
  final location = _locationController.text.trim();
  final phone = _phoneController.text.trim();
  final promo = _promoController.text.trim();

  if (name.isEmpty || location.isEmpty || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all fields')),
    );
    return;
  }

  if (promo.isNotEmpty) {
    try {
      final result = await PromoService.validatePromo(promo);
      final type = result['discountType'];
      final value = result['discountValue'];

      double rawTotal = totalAmountWithoutDiscount;
      if (type == 'percentage') {
        discountAmount = rawTotal * (value / 100);
      } else {
        discountAmount = value;
      }
      appliedPromoCode = promo;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid promo code: $e')),
      );
      return;
    }
  }

  try {
    await widget.cartService.placeOrder(phone, name, location);

    // ✅ Save buyer name to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('buyerName', name);
    await prefs.setString('buyerPhone', phone);

    setState(() {
      cartItems = [];
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutSuccessScreen(
          promoCode: appliedPromoCode,
          discountAmount: discountAmount,
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to place order: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB0C4DE), Color(0xFF4682B4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'TRADY',
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        actions: [
          Badge.count(
            count: cartItems.length,
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Enter your name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Enter delivery location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Enter phone number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _promoController,
                    decoration: const InputDecoration(
                      labelText: 'Promo Code (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              itemCount: cartItems.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) {
                final item = cartItems[i];
                final imageUrl = item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? ImageUtils.buildFullImageUrl(item.imageUrl!)
                    : null;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey,
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.image, color: Colors.grey),
                                ),
                              ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (item.isBargain)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Bargain',
                              style: TextStyle(
                                color: Color(0xFF8B0000),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (item.isGroupBuy)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Group Buy',
                              style: TextStyle(color: Colors.purple, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      'Qty: ${item.quantity} • ${_currency.format(item.price)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          removeItem(item.productId, isBargain: item.isBargain),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(_currency.format(totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: syncCart,
              icon: const Icon(Icons.sync),
              label: const Text('Checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4682B4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: placeOrder,
              icon: const Icon(Icons.check_circle),
              label: const Text('Place Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
