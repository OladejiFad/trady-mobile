import 'package:flutter/material.dart';
import '../../models/group_buy_model.dart';

class GroupBuyCard extends StatelessWidget {
  final GroupBuy groupBuy;
  final VoidCallback? onRefresh;
  final VoidCallback? onJoin;

  const GroupBuyCard({
    super.key,
    required this.groupBuy,
    this.onRefresh,
    this.onJoin,
  });

  String _resolveImageUrl(String rawImage) {
    const baseUrl = 'http://172.20.10.2:5000';

    if (rawImage.startsWith('http')) return rawImage;

    String path = rawImage;
    if (path.startsWith('/uploads/uploads/')) {
      path = path.replaceFirst('/uploads/uploads/', '/uploads/');
    } else if (path.startsWith('uploads/uploads/')) {
      path = path.replaceFirst('uploads/uploads/', 'uploads/');
    }

    if (!path.startsWith('/')) path = '/$path';
    return '$baseUrl$path';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(groupBuy.product.image);
    final isFull = groupBuy.joinedQuantity >= groupBuy.minParticipants;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 6,
      shadowColor: Colors.deepPurple.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 120,
                  child: Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  ),
                ),
              ),
            ),

            // 📦 Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupBuy.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${groupBuy.pricePerUnit.toStringAsFixed(0)} / unit',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (groupBuy.minParticipants == 0)
                          ? 0
                          : (groupBuy.joinedQuantity / groupBuy.minParticipants).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.grey[300],
                      color: isFull ? Colors.green : Colors.deepPurple,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Joined: ${groupBuy.joinedQuantity}/${groupBuy.minParticipants}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          'Ends: ${groupBuy.deadline.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isFull
                      ? null
                      : onJoin ??
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Join action not implemented')),
                            );
                          },
                  icon: Icon(
                    isFull ? Icons.check_circle_outline : Icons.group_add,
                    size: 16,
                  ),
                  label: Text(
                    isFull ? 'Group Full ✅' : 'Join Now',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFull ? Colors.grey : Colors.deepPurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
