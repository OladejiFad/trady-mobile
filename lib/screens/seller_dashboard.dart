import 'package:flutter/material.dart';
import '../tabs/seller_dashboard_tabs.dart';

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SellerDashboardScreen(),
      ),
    );
  }
}
