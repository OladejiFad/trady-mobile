// lib/screens/buyer/all_promos_screen.dart
import 'package:flutter/material.dart';
import '../../services/promo_service.dart';
import '../../models/promo_model.dart';

class AllPromosScreen extends StatelessWidget {
  const AllPromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔥 Deals & Promos')),
      body: FutureBuilder<List<Promo>>(
        future: PromoService.fetchAllPromos(), // Create an endpoint if needed
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final promos = snapshot.data!;
          return ListView.builder(
            itemCount: promos.length,
            itemBuilder: (context, i) {
              final promo = promos[i];
              return ListTile(
                leading: const Icon(Icons.local_offer),
                title: Text('${promo.code} - ${promo.discountType == 'percentage' ? '${promo.discountValue}% OFF' : '₦${promo.discountValue} OFF'}'),
                subtitle: Text('Expires: ${promo.expiresAt.toLocal()}'),
                trailing: TextButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: promo.code)),
                  child: const Text('Copy Code'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
