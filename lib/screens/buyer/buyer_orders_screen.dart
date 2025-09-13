import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/buyer_order_service.dart';
import 'package:intl/intl.dart';
import 'tracking_screen.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({Key? key}) : super(key: key);

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String? error;
  final _currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦');
  String? buyerPhone;

  @override
  void initState() {
    super.initState();
    fetchBuyerOrders();
  }

  Future<void> fetchBuyerOrders() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      buyerPhone = prefs.getString('buyerPhone');

      if (buyerPhone == null || buyerPhone!.isEmpty) {
        throw 'No buyer phone number found. Go track an order first.';
      }

      final buyerOrderService = BuyerOrderService();
      final data = await buyerOrderService.getOrders(buyerPhone!);

      setState(() => orders = data);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : orders.isEmpty
                  ? const Center(child: Text('No orders found.'))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final products = (order['products'] as List)
                            .map((p) => '- ${p['quantity']} x ${p['productId']} @ ₦${p['price']}')
                            .join('\n');

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order ID: ${order['orderId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Location: ${order['buyerLocation']}'),
                                const SizedBox(height: 4),
                                Text(products),
                                const SizedBox(height: 4),
                                Text('Status: ${order['deliveryStatus']}'),
                                Text('Satisfaction: ${order['satisfactionStatus']}'),
                                Text('Payment: ${order['paymentStatus']}'),
                                Text('Created: ${order['createdAt']}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TrackingScreen(),
            ),
          );
        },
        icon: const Icon(Icons.location_on),
        label: const Text('Track My Order'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
