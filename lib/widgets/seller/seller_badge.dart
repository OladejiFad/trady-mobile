// lib/widgets/seller/seller_badge.dart
import 'package:flutter/material.dart';

class SellerBadge extends StatelessWidget {
  final double score;

  const SellerBadge({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (score > 95) {
      return const Chip(
        label: Text('🥇 Top Seller'),
        backgroundColor: Colors.amber,
      );
    } else if (score > 85) {
      return const Chip(
        label: Text('✅ Reliable'),
        backgroundColor: Colors.greenAccent,
      );
    } else {
      return Chip(
        label: Text('${score.toStringAsFixed(1)}% Score'),
        backgroundColor: Colors.grey.shade300,
      );
    }
  }
}
