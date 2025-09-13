import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/store_model.dart';
import '../../models/promo_model.dart';
import '../../screens/buyer_product_list_screen.dart';
import '../seller/seller_badge.dart';
import 'top_seller_badge.dart';

class StoreProfileCard extends StatelessWidget {
  final Store store;
  final List<Promo> promos;
  final double height;
  final VoidCallback? onEnterPressed;

  const StoreProfileCard({
    Key? key,
    required this.store,
    required this.promos,
    this.height = 280,
    this.onEnterPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, String> themeImages = {
      'Scandinavian Minimal': 'https://images.pexels.com/photos/1350789/pexels-photo-1350789.jpeg',
      'Tokyo Night': 'https://images.pexels.com/photos/291762/pexels-photo-291762.jpeg',
      'Urban Chic': 'https://images.pexels.com/photos/1080696/pexels-photo-1080696.jpeg',
      'Bohemian Vibrant': 'https://images.pexels.com/photos/1054974/pexels-photo-1054974.jpeg',
      'Coastal Serenity': 'https://images.pexels.com/photos/775219/pexels-photo-775219.jpeg',
      'Rustic Charm': 'https://images.pexels.com/photos/1084188/pexels-photo-1084188.jpeg',
      'Modern Loft': 'https://images.pexels.com/photos/2635038/pexels-photo-2635038.jpeg',
      'Vintage Retro': 'https://images.pexels.com/photos/1632790/pexels-photo-1632790.jpeg',
      'Tropical Oasis': 'https://images.pexels.com/photos/1693946/pexels-photo-1693946.jpeg',
      'Industrial Edge': 'https://images.pexels.com/photos/209251/pexels-photo-209251.jpeg',
      'Midnight Blue': 'https://images.pexels.com/photos/1629236/pexels-photo-1629236.jpeg',
      'Desert Sunset': 'https://images.pexels.com/photos/360912/pexels-photo-360912.jpeg',
      'Forest Whisper': 'https://images.pexels.com/photos/15286/pexels-photo.jpg',
      'Urban Jungle': 'https://images.pexels.com/photos/2901581/pexels-photo-2901581.jpeg',
      'Classic Elegance': 'https://images.pexels.com/photos/813692/pexels-photo-813692.jpeg',
      'Nordic Frost': 'https://images.pexels.com/photos/164338/pexels-photo-164338.jpeg',
      'Sunlit Meadow': 'https://images.pexels.com/photos/1586298/pexels-photo-1586298.jpeg',
      'Cosmic Dream': 'https://images.pexels.com/photos/355465/pexels-photo-355465.jpeg',
      'Art Deco Glam': 'https://images.pexels.com/photos/2100487/pexels-photo-2100487.jpeg',
      'Minimal Zen': 'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg',
    };

    final storeTheme = store.storeTheme;

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4A017), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        color: Colors.white,
      ),
      child: Column(
        children: [
          // 🔹 Theme Image
          Container(
            height: height * 0.45,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: storeTheme != null && themeImages.containsKey(storeTheme)
                  ? DecorationImage(
                      image: NetworkImage(themeImages[storeTheme]!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),


          // 🔹 Details Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔸 Store Name + Top Seller Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.storeName.isNotEmpty ? store.storeName : "❌ No Name",
                          style: GoogleFonts.cinzel(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (store.isTopSeller)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: TopSellerBadge(),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // 🔸 Description
                  if (store.storeDescription.isNotEmpty)
                    Flexible(
                      child: Text(
                        store.storeDescription,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),

                  // ✅ Promo Banner
                  if (promos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "🎉${promos.first.code} - ${promos.first.discountType == 'percentage' ? '${promos.first.discountValue}% OFF' : '₦${promos.first.discountValue} OFF'} (Valid till ${DateFormat('d MMM').format(promos.first.expiresAt)})",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 6),

                  // 🔸 Detail Chips (Category, Occupation, Type)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _detailChip("Category", store.storeCategory),
                      _detailChip("Occupation", store.storeOccupation),
                      _detailChip("Type", store.occupationType),
                    ],
                  ),

                  const Spacer(),

                  // 🔸 Seller Score badge
                  Align(
                    alignment: Alignment.centerRight,
                    child: SellerBadge(score: store.storeScore ?? 0),
                  ),

                  const SizedBox(height: 8),

                  // ✅ Optional "Enter Store" button
                  if (onEnterPressed != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.store),
                        label: const Text("Enter Store"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2E6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: onEnterPressed,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Chip(
      label: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: const Color(0xFFFFF7E6),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
