import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/property_model.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onMessageLandlord;
  final VoidCallback? onEdit;

  const PropertyCard({
    Key? key,
    required this.property,
    required this.onMessageLandlord,
    this.onEdit,
  }) : super(key: key);

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black.withOpacity(0.8),
        child: Stack(
          children: [
            Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                loadingBuilder: (context, child, loadingProgress) =>
                    loadingProgress == null
                        ? child
                        : const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100, color: Colors.white),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    const icons = {
      'wifi': Icons.wifi,
      'wi-fi': Icons.wifi,
      'parking': Icons.local_parking,
      'pool': Icons.pool,
      'gym': Icons.fitness_center,
      'ac': Icons.ac_unit,
      'air conditioning': Icons.ac_unit,
      'heating': Icons.thermostat,
      'kitchen': Icons.kitchen,
      'tv': Icons.tv,
      'washer': Icons.local_laundry_service,
      'dryer': Icons.local_laundry_service,
      'balcony': Icons.balcony,
      'garden': Icons.park,
      'security': Icons.security,
      'elevator': Icons.elevator,
      'pets allowed': Icons.pets,
      'furnished': Icons.chair,
    };
    return icons[lower] ?? Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final isRent = (property.transactionType?.toLowerCase() ?? '') == 'rent';
    final imageUrl = (property.images?.isNotEmpty ?? false)
        ? (property.images!.first.startsWith('http')
            ? property.images!.first
            : 'http://172.20.10.2:5000${property.images!.first}')
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  GestureDetector(
                    onTap: () => _showFullImage(context, imageUrl),
                    child: AspectRatio(
                      aspectRatio: isWide ? 21 / 9 : 16 / 9,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null
                                ? child
                                : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image, size: 70, color: Colors.grey)),
                      ),
                    ),
                  )
                else
                  Container(
                    height: isWide ? 250 : 200,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.apartment, size: 70, color: Colors.grey)),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title ?? 'No Title',
                          style: TextStyle(
                            fontSize: isWide ? 20 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₦${property.price?.toStringAsFixed(2) ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(property.type ?? 'Unknown').toUpperCase()} • ${(property.transactionType ?? 'Unknown').toUpperCase()}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            property.location.address ?? '',
                            property.location.city ?? '',
                            property.location.state ?? '',
                          ].where((e) => e.isNotEmpty).join(', '),
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (property.bedrooms != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('Bedrooms: ${property.bedrooms}', style: const TextStyle(fontSize: 12)),
                          ),
                        if (property.amenities?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: property.amenities!.asMap().entries.map((entry) {
                                final index = entry.key;
                                final amenity = entry.value;
                                final chipColor = [
                                  Colors.blue.shade50,
                                  Colors.green.shade50,
                                  Colors.orange.shade50,
                                  Colors.purple.shade50,
                                ][index % 4];

                                return Chip(
                                  avatar: Icon(_getAmenityIcon(amenity), size: 14, color: Colors.black87),
                                  label: Text(amenity, style: const TextStyle(fontSize: 10)),
                                  backgroundColor: chipColor,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                );
                              }).toList(),
                            ),
                          ),
                        if (isRent && property.availability != null) ...[
                          const SizedBox(height: 6),
                          Text('Available: ${property.availability!.isAvailable ? "Yes" : "No"}',
                              style: const TextStyle(fontSize: 12)),
                          if (property.availability!.availableFrom != null)
                            Text(
                              'From: ${DateFormat.yMMMd().format(property.availability!.availableFrom!)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (property.availability!.leaseDurationMonths != null)
                            Text('Lease Duration: ${property.availability!.leaseDurationMonths} months',
                                style: const TextStyle(fontSize: 12)),
                        ],
                        if (property.description != null && property.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              property.description!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                            ),
                          ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.message, size: 16),
                                label: const Text('Message'),
                                onPressed: onMessageLandlord,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                              if (onEdit != null)
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: onEdit,
                                  tooltip: 'Edit Property',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
