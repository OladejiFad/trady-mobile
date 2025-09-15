import 'package:flutter/material.dart';
import '../services/market_service.dart';

class MarketDayBanner extends StatelessWidget {
  final String role; // 'buyer' or 'seller'
  final Color? color; // optional override color

  const MarketDayBanner({required this.role, this.color, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: MarketService.fetchMarketDayInfo(role),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        // Error or null data
        if (snapshot.hasError || snapshot.data == null) {
          return _buildBanner(
            '⚠️ Market status unavailable',
            Colors.grey,
          );
        }

        final data = snapshot.data!;
        final isActive = data['active'] as bool? ?? false;

        // Safely parse dates
        final now = DateTime.tryParse(data['now']?.toString() ?? '') ?? DateTime.now();
        final openTime = DateTime.tryParse(data['openTime']?.toString() ?? '') ?? now;
        final closeTime = DateTime.tryParse(data['closeTime']?.toString() ?? '') ?? now;

        final nowIsSunday = now.weekday == DateTime.sunday;

        if (isActive) {
          return _buildBanner(
            '🎉 Market Day is ACTIVE now! Special sections are open!',
            color ?? Colors.green,
          );
        }

        if (nowIsSunday && now.isBefore(openTime)) {
          String timeText = role == 'buyer' ? '3:00 PM' : '1:00 PM';
          return _buildBanner(
            '⏳ Market Day starts today at $timeText!',
            color ?? Colors.deepOrange.shade300,
          );
        }

        // Default banner
        return _buildBanner(
          '🗓️ Market Day opens Sunday at ${_formatTime(openTime)}!',
          color ?? Colors.grey.shade400,
        );
      },
    );
  }

  Widget _buildBanner(String message, Color backgroundColor) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.all(12),
      child: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minutes = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minutes $ampm';
  }
}
