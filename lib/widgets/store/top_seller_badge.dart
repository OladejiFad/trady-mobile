import 'package:flutter/material.dart';

class TopSellerBadge extends StatelessWidget {
  const TopSellerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade800,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          Icon(Icons.star, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Top Seller',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
