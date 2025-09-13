import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/land_lord_model.dart';

// Define a classic color palette for elegance
const Color primaryTeal = Color(0xFF004D40);
const Color accentGold = Color(0xFFD4A017);
const Color backgroundGradientStart = Color(0xFFF5F7FA);
const Color backgroundGradientEnd = Color(0xFFE2E8F0);

class ApproveRejectLandlordsWidget extends StatefulWidget {
  const ApproveRejectLandlordsWidget({Key? key}) : super(key: key);

  @override
  State<ApproveRejectLandlordsWidget> createState() => _ApproveRejectLandlordsWidgetState();
}

class _ApproveRejectLandlordsWidgetState extends State<ApproveRejectLandlordsWidget> {
  late Future<List<LandlordModel>> _pendingLandlordsFuture;

  @override
  void initState() {
    super.initState();
    _loadPendingLandlords();
  }

  /// Loads pending landlords from AdminService
  void _loadPendingLandlords() {
    _pendingLandlordsFuture = AdminService.getPendingLandlords();
  }

  /// Handles approve or reject action for a landlord
  Future<void> _handleApproveReject(String landlordId, bool approve) async {
    final success = await AdminService.approveOrRejectLandlord(landlordId, approve);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Landlord approved successfully' : 'Landlord rejected successfully',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: approve ? primaryTeal : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() {
        _loadPendingLandlords(); // Refresh list after action
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to update landlord status',
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
      child: FutureBuilder<List<LandlordModel>>(
        future: _pendingLandlordsFuture,
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

          final landlords = snapshot.data ?? [];
          // Empty state
          if (landlords.isEmpty) {
            return Center(
              child: _buildEmptyCard(),
            );
          }

          // List of landlords
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            itemCount: landlords.length,
            itemBuilder: (context, index) {
              final landlord = landlords[index];
              return FadeInAnimation(
                duration: const Duration(milliseconds: 600),
                delay: Duration(milliseconds: index * 100),
                child: _buildLandlordCard(landlord),
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
              'No pending landlords',
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

  /// Builds a beautifully styled card for each landlord
  Widget _buildLandlordCard(LandlordModel landlord) {
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
              Text(
                landlord.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryTeal,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Phone: ${landlord.phone}'),
              _buildInfoRow(Icons.location_on, 'Location: ${landlord.location}'),
              _buildInfoRow(Icons.account_balance, 'BVN: ${landlord.bvn}'),
              _buildInfoRow(Icons.fingerprint, 'NIN: ${landlord.nin}'),
              if (landlord.internationalPassport?.isNotEmpty == true)
                _buildInfoRow(Icons.flight, 'International Passport: ${landlord.internationalPassport}'),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.check,
                    color: Colors.green.shade600,
                    tooltip: 'Approve Landlord',
                    onPressed: () => _handleApproveReject(landlord.id, true),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.close,
                    color: Colors.red.shade600,
                    tooltip: 'Reject Landlord',
                    onPressed: () => _handleApproveReject(landlord.id, false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a row for landlord information with an icon
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

  /// Builds a styled action button for approve/reject
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
