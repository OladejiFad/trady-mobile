import 'package:flutter/material.dart';
import '../services/market_service.dart';

class MarketDayBanner extends StatefulWidget {
  final String role; // 'buyer' or 'seller'
  final Color? color; // optional override color

  const MarketDayBanner({required this.role, this.color, Key? key}) : super(key: key);

  @override
  _MarketDayBannerState createState() => _MarketDayBannerState();
}

class _MarketDayBannerState extends State<MarketDayBanner> {
  bool? _isActive;
  bool _loading = true;
  DateTime? _now;
  DateTime? _openTime;
  DateTime? _closeTime;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final result = await MarketService.fetchMarketDayInfo(widget.role);
      setState(() {
        _isActive = result['active'];
        _now = DateTime.parse(result['now']);
        _openTime = DateTime.parse(result['openTime']);
        _closeTime = DateTime.parse(result['closeTime']);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _isActive = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final today = _now!;
    final open = _openTime!;
    final close = _closeTime!;
    final nowIsSunday = today.weekday == DateTime.sunday;

    if (_isActive == true) {
      return _buildBanner(
        '🎉 Market Day is ACTIVE now! Special sections are open!',
        widget.color ?? Colors.orangeAccent,
      );
    }

    if (nowIsSunday && today.isBefore(open)) {
      String timeText = widget.role == 'buyer' ? '3:00 PM' : '1:00 PM';
      return _buildBanner(
        '⏳ Market Day starts today at $timeText!',
        widget.color ?? Colors.deepOrange.shade100,
      );
    }

    // Always show banner even on non-Sunday
    return _buildBanner(
      '🗓️ Market Day opens Sunday at ${_formatTime(open)}!',
      widget.color ?? Colors.grey.shade300,
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minutes = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minutes $ampm';
  }

  Widget _buildBanner(String message, Color backgroundColor) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.all(12),
      child: Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
