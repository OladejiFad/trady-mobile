import 'package:flutter/material.dart';
import '../../services/seller_tracking_service.dart';
import '../../helpers/status_color_helper.dart';

class SellerOrdersTrackingScreen extends StatefulWidget {
  final String sellerId;
  final String token;

  const SellerOrdersTrackingScreen({
    super.key,
    required this.sellerId,
    required this.token,
  });

  @override
  State<SellerOrdersTrackingScreen> createState() =>
      _SellerOrdersTrackingScreenState();
}

class _SellerOrdersTrackingScreenState
    extends State<SellerOrdersTrackingScreen> {
  bool isLoading = false;
  Map<String, dynamic>? trackingData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTrackingData();
  }

  Future<void> _fetchTrackingData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await SellerTrackingService.trackBySeller(
          widget.sellerId, widget.token);
      setState(() {
        trackingData = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load tracking data:\n${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateShipmentStatus(String orderId, String status) async {
    setState(() {
      isLoading = true;
    });

    try {
      await SellerTrackingService.updateShipmentStatus(
          orderId, status, widget.token);
      await _fetchTrackingData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update shipment status: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildOrders() {
    final orders = trackingData?['orders'] ?? [];
    if (orders.isEmpty) return const Center(child: Text('No Orders'));

    return RefreshIndicator(
      onRefresh: _fetchTrackingData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final o = orders[i];
          final products = (o['products'] as List)
              .map((p) =>
                  '• ${p['quantity']} x ${p['productName'] ?? p['productId']} @ ₦${p['price']}')
              .join('\n');

          final deliveryStatus = (o['shipmentStatus'] ?? '').toString();
          final satisfactionStatus = (o['satisfactionStatus'] ?? '').toString();
          final paymentStatus = (o['paymentStatus'] ?? '').toString();
          final orderStatus = (o['orderStatus'] ?? '').toString();

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🧾 Order ID: ${o['orderId']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('👤 Buyer: ${o['buyerName']} (${o['buyerPhone']})'),
                  Text('📍 Location: ${o['buyerLocation']}'),
                  const Divider(height: 20),
                  Text(products, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                            '💰 Payment: ${StatusColorHelper.paymentLabel(paymentStatus)}'),
                        backgroundColor:
                            StatusColorHelper.paymentColor(paymentStatus),
                      ),
                      Chip(
                        label: Text(
                            '📦 Shipment: ${StatusColorHelper.shipmentLabel(deliveryStatus)}'),
                        backgroundColor:
                            StatusColorHelper.shipmentColor(deliveryStatus)
                                .withOpacity(0.2),
                      ),
                      Chip(
                        label: Text(
                            'Satisfaction: ${StatusColorHelper.satisfactionLabel(satisfactionStatus)}'),
                        backgroundColor:
                            StatusColorHelper.satisfactionColor(satisfactionStatus)
                                .withOpacity(0.2),
                      ),
                      Chip(
                        label: Text(
                            '📝 Order: ${StatusColorHelper.orderStatusLabel(orderStatus)}'),
                        backgroundColor:
                            StatusColorHelper.orderStatusColor(orderStatus),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Shipment Status (Seller-controlled)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ElevatedButton(
                    onPressed: (deliveryStatus.toLowerCase() == 'delivered' ||
                            isLoading)
                        ? null
                        : () => _updateShipmentStatus(
                            o['orderId'], 'Out for Delivery'),
                    child: const Text('Mark Out for Delivery'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Other Statuses (Buyer/Admin-controlled)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: null,
                        child: Text(
                            StatusColorHelper.paymentLabel(paymentStatus)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              StatusColorHelper.paymentColor(paymentStatus),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: null,
                        child: Text(StatusColorHelper
                            .satisfactionLabel(satisfactionStatus)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deliveryStatus.trim().toLowerCase() == 'delivered'
                          ? StatusColorHelper.shipmentColor(deliveryStatus)
                          : StatusColorHelper.shipmentColor(deliveryStatus).withOpacity(0.2),

                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: null,
                        child: Text(
                            StatusColorHelper.orderStatusLabel(orderStatus)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              StatusColorHelper.orderStatusColor(orderStatus),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('📅 Created: ${o['createdAt'] ?? 'N/A'}',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Order Tracking')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : trackingData != null
                  ? _buildOrders()
                  : const Center(child: Text('No data available')),
    );
  }
}
