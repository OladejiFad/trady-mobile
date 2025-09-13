import 'package:flutter/material.dart';
import '../../services/seller_order_service.dart';
import '../../models/order_model.dart'; // Adjust path as needed

class SellerOrdersScreen extends StatefulWidget {
  final String sellerId;
  final String token;

  const SellerOrdersScreen({
    Key? key,
    required this.sellerId,
    required this.token,
  }) : super(key: key);

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  List<Order> orders = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final result = await SellerOrderService.fetchSellerOrders(widget.sellerId, widget.token);
      setState(() {
        orders = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
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
                      padding: const EdgeInsets.all(12),
                      itemCount: orders.length,
                      itemBuilder: (_, index) {
                        final order = orders[index];
                        final productsList = order.products;

                        final items = productsList
                            .map((p) =>
                                '- ${p.quantity} x ${p.productName.isNotEmpty ? p.productName : p.productId} @ ₦${p.price}')
                            .join('\n');

                        return Card(
                          child: ListTile(
                            title: Text('Order ID: ${order.orderId}'),
                            subtitle: Text(
                              'Buyer: ${order.buyerName} (${order.buyerPhone})\n'
                              'Location: ${order.buyerLocation}\n\n'
                              '$items\n\n'
                              'Status: ${order.deliveryStatus} • Payment: ${order.paymentStatus}',
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
