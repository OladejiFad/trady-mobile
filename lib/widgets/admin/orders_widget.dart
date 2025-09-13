import 'package:flutter/material.dart';
import '../../helpers/status_color_helper.dart';
import '../../services/admin_order_service.dart';
import '../../models/order_model.dart';

class AdminOrdersWidget extends StatelessWidget {
  final List<Order> orders;
  final VoidCallback onStatusUpdated;

  const AdminOrdersWidget({
    Key? key,
    required this.orders,
    required this.onStatusUpdated,
  }) : super(key: key);

  void _updateStatusDialog(
    BuildContext context,
    String orderId,
    String field,
    String currentValue,
  ) {
    final List<String> options = _getOptions(field);
    if (options.isEmpty) return;

    String? selected = options.contains(currentValue) ? currentValue : options.first;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update $field'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: selected,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: options
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selected = val);
                }
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AdminOrderService.updateOrderStatus(orderId, field, selected!);

              if (field == 'orderStatus') {
                final newPaymentStatus =
                    (selected == 'Success') ? 'success' : 'refund';
                await AdminOrderService.updateOrderStatus(orderId, 'paymentStatus', newPaymentStatus);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$field updated to $selected')),
              );

              onStatusUpdated();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  List<String> _getOptions(String field) {
    switch (field) {
      case 'paymentStatus':
        return ['with BuyNest', 'Pending', 'success', 'refund'];
      case 'orderStatus':
        return ['Processing', 'Success', 'Failed'];
      default:
        return [];
    }
  }

  Widget _buildStatusChip(BuildContext context, Order order, String field) {
    late String value;
    switch (field) {
      case 'paymentStatus':
        value = (order.paymentStatus?.trim().isEmpty ?? true)
            ? 'with BuyNest'
            : order.paymentStatus!;
        break;
      case 'shipmentStatus':
        value = order.shipmentStatus;
        break;
      case 'satisfactionStatus':
        value = order.satisfactionStatus;
        break;
      case 'orderStatus':
        final raw = order.orderStatus;
        value = (raw?.trim().isEmpty ?? true) ? 'Processing' : raw!.trim();
        break;
    }

    Color chipColor;
    String labelText;

    if (field == 'shipmentStatus') {
      chipColor = StatusColorHelper.shipmentColor(value);
      labelText = StatusColorHelper.shipmentLabel(value);
    } else if (field == 'satisfactionStatus') {
      chipColor = StatusColorHelper.satisfactionColor(value);
      labelText = StatusColorHelper.satisfactionLabel(value);
    } else if (field == 'paymentStatus') {
      chipColor = StatusColorHelper.paymentColor(value);
      labelText = StatusColorHelper.paymentLabel(value);
    } else if (field == 'orderStatus') {
      chipColor = (value == 'Success')
          ? Colors.green
          : (value == 'Failed')
              ? Colors.red
              : Colors.grey;
      labelText = value;
    } else {
      chipColor = Colors.grey[200]!;
      labelText = value;
    }

    final options = _getOptions(field);
    final canEdit = options.isNotEmpty;

    bool isClickable = false;

    if (field == 'paymentStatus') {
      isClickable = (value == 'with BuyNest' || value == 'Pending');
    } else if (field == 'orderStatus') {
      isClickable = (value == 'Processing');
    }

    return canEdit && isClickable
        ? InputChip(
            label: Text('$field: $labelText'),
            backgroundColor: chipColor,
            onPressed: () =>
                _updateStatusDialog(context, order.orderId, field, value),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          )
        : Chip(
            label: Text('$field: $labelText'),
            backgroundColor: chipColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
  }

  Widget _buildProductList(List<ProductInOrder> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: products.map((p) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text('• ${p.quantity} x ${p.productName} @ ₦${p.price}',
              style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final order = orders[i];
        final createdAt = order.createdAt ?? order.orderId.substring(0, 10);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🧾 Order ID: ${order.orderId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text('👤 ${order.buyerName} (${order.buyerPhone})',
                    style: const TextStyle(fontSize: 14)),
                Text('📍 ${order.buyerLocation}',
                    style: const TextStyle(fontSize: 14)),
                const Divider(height: 20, thickness: 1.2),
                _buildProductList(order.products),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip(context, order, 'paymentStatus'),
                    _buildStatusChip(context, order, 'shipmentStatus'),
                    _buildStatusChip(context, order, 'satisfactionStatus'),
                    _buildStatusChip(context, order, 'orderStatus'),
                  ],
                ),
                const SizedBox(height: 12),
                Text('📅 Created: $createdAt',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
