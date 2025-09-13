import 'package:flutter/material.dart';
import '../../models/group_buy_model.dart';
import '../../services/group_buy_service.dart';

class GroupBuyPaymentScreen extends StatefulWidget {
  final GroupBuy groupBuy;
  final String participantPhone;
  final VoidCallback onPaymentSuccess;

  const GroupBuyPaymentScreen({
    super.key,
    required this.groupBuy,
    required this.participantPhone,
    required this.onPaymentSuccess,
  });

  @override
  State<GroupBuyPaymentScreen> createState() => _GroupBuyPaymentScreenState();
}

class _GroupBuyPaymentScreenState extends State<GroupBuyPaymentScreen> {
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await GroupBuyService()
          .payForGroupBuy(widget.groupBuy.id, widget.participantPhone);

      await GroupBuyService()
          .addToCartFromGroupBuy(widget.groupBuy.id, widget.participantPhone);

      widget.onPaymentSuccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful! Added to cart.')),
        );
        Navigator.pop(context); // Close payment screen
        Navigator.pop(context); // Close join form if still open
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.groupBuy.pricePerUnit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Buy Payment'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pay ₦${price.toStringAsFixed(0)} to join "${widget.groupBuy.title}"',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Pay Now', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
