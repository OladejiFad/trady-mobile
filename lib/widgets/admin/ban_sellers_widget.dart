import 'package:flutter/material.dart';
import '../../models/seller_model.dart';
import '../../services/admin_service.dart';

// Define a classic color palette for elegance
const Color primaryTeal = Color(0xFF004D40);
const Color accentGold = Color(0xFFD4A017);
const Color backgroundGradientStart = Color(0xFFF5F7FA);
const Color backgroundGradientEnd = Color(0xFFE2E8F0);

class BanSellersWidget extends StatefulWidget {
  const BanSellersWidget({Key? key}) : super(key: key);

  @override
  State<BanSellersWidget> createState() => _BanSellersWidgetState();
}

class _BanSellersWidgetState extends State<BanSellersWidget> {
  late Future<List<SellerModel>> _sellersFuture;

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  /// Loads all sellers from AdminService
  void _loadSellers() {
    _sellersFuture = AdminService.getAllSellers();
  }

  /// Toggles ban status for a seller
  Future<void> _toggleBanStatus(SellerModel seller, bool ban) async {
    final success = await AdminService.banOrUnbanSeller(seller.id, ban);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ban ? '✅ ${seller.name} banned successfully' : '✅ ${seller.name} unbanned successfully',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: ban ? Colors.red.shade700 : primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() {
        _loadSellers(); // Refresh list after action
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '❌ Failed to update seller status',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundGradientStart, backgroundGradientEnd],
        ),
      ),
      child: FutureBuilder<List<SellerModel>>(
        future: _sellersFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryTeal,
                strokeWidth: 3,
              ),
            );
          }
          // Error state
          if (snapshot.hasError) {
            return Center(
              child: _buildErrorCard('Error: ${snapshot.error}'),
            );
          }

          final sellers = snapshot.data ?? [];
          // Empty state
          if (sellers.isEmpty) {
            return Center(
              child: _buildEmptyCard(),
            );
          }

          // List of sellers
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            itemCount: sellers.length,
            itemBuilder: (context, index) {
              final seller = sellers[index];
              return FadeInAnimation(
                duration: const Duration(milliseconds: 600),
                delay: Duration(milliseconds: index * 100),
                child: _buildSellerCard(seller),
              );
            },
          );
        },
      ),
    );
  }

  /// Builds an elegant card for displaying error messages
  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontFamily: 'Georgia',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card for the empty state
  Widget _buildEmptyCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 40,
              color: primaryTeal,
            ),
            const SizedBox(height: 12),
            const Text(
              'No sellers found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontFamily: 'Georgia',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a beautifully styled card for each seller
  Widget _buildSellerCard(SellerModel seller) {
    final isBanned = seller.banned; // Check ban status

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF7FAFC)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      seller.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: primaryTeal,
                        fontFamily: 'Georgia',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBanned ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isBanned ? 'Banned' : 'Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: isBanned ? Colors.red.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Phone: ${seller.phone}'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: isBanned ? Icons.check_circle : Icons.block,
                    color: isBanned ? Colors.green.shade600 : Colors.red.shade600,
                    tooltip: isBanned ? 'Unban Seller' : 'Ban Seller',
                    onPressed: () => _toggleBanStatus(seller, !isBanned),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a row for seller information with an icon
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: accentGold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontFamily: 'Roboto',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a styled action button for ban/unban
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// FadeInAnimation widget for smooth card transitions
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  _FadeInAnimationState createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}