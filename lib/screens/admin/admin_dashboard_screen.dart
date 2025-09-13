import 'package:flutter/material.dart';
import '../../global/admin_auth_data.dart';
import '../../widgets/admin/approve_reject_sellers_widget.dart';
import '../../widgets/admin/ban_sellers_widget.dart';
import '../../widgets/admin/approve_reject_landlords_widget.dart';
import '../../widgets/admin/ban_landlords_widget.dart';
import '../../widgets/admin/admin_reminders_widget.dart';
import '../../widgets/admin/orders_widget.dart';
import '../../widgets/admin/refunds_widget.dart';
import '../../widgets/admin/products_widget.dart';
import '../../widgets/admin/complaints_widgets.dart';
import '../../widgets/admin/admin_pending_properties_screen.dart';
import '../../screens/admin/create_job_screen.dart';
import '../../models/order_model.dart';
import '../../services/admin_order_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String selectedTab = 'Approve Sellers';

  List<Order> adminOrders = [];
  bool isLoadingOrders = true;
  String? ordersError;

  final Map<String, Widget Function()> tabViews = {};

  @override
  void initState() {
    super.initState();
    fetchAdminOrders();

    tabViews.addAll({
      'Approve Sellers': () => const ApproveRejectSellersWidget(),
      'Ban Sellers': () => const BanSellersWidget(),
      'Approve Landlords': () => const ApproveRejectLandlordsWidget(),
      'Ban Landlords': () => const BanLandlordsWidget(),
      'Pending Properties': () => const AdminPendingPropertiesScreen(),
      'Reminders': () => const AdminRemindersWidget(),
      'Orders': () => buildOrdersTab(),
      'Refunds': () => const RefundsWidget(),
      'Products': () => const ProductsWidget(),
      'Stats': () => const Center(child: Text('📊 Statistics coming soon!')),
      'Complaints': () => AdminComplaintsWidget(adminToken: AdminAuthData.token),
      'Feedback': () => const Center(child: Text('💬 Feedback UI here')),
      'Stores': () => const Center(child: Text('🏪 Stores overview')),
      'Create Trady Job': () => const CreateJobScreen(),
    });
  }

  void handleLogout() {
    AdminAuthData.token = '';
    AdminAuthData.adminId = '';
    AdminAuthData.username = '';
    Navigator.pushReplacementNamed(context, '/admin/auth');
  }

  Future<void> fetchAdminOrders() async {
    setState(() {
      isLoadingOrders = true;
      ordersError = null;
    });

    try {
      final orders = await AdminOrderService.fetchOrders();
      setState(() {
        adminOrders = orders;
        isLoadingOrders = false;
      });
    } catch (e) {
      setState(() {
        ordersError = e.toString();
        isLoadingOrders = false;
      });
    }
  }

  Widget buildOrdersTab() {
    if (isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    } else if (ordersError != null) {
      return Center(child: Text('Error loading orders: $ordersError'));
    } else {
      return AdminOrdersWidget(
        orders: adminOrders,
        onStatusUpdated: fetchAdminOrders,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sideTabs = tabViews.keys.toList();
    final currentWidget = tabViews[selectedTab]!();

    return Scaffold(
      body: Row(
        children: [
          /// ✅ Safe scrollable NavigationRail
          SizedBox(
            width: 80,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: sideTabs.indexOf(selectedTab),
                    onDestinationSelected: (int index) {
                      setState(() => selectedTab = sideTabs[index]);
                    },
                    labelType: NavigationRailLabelType.all,
                    leading: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        const Icon(Icons.admin_panel_settings, size: 32),
                        const SizedBox(height: 10),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: 'Logout',
                          onPressed: handleLogout,
                        ),
                      ],
                    ),
                    destinations: sideTabs
                        .map((label) => NavigationRailDestination(
                              icon: _getIconForLabel(label),
                              label: Text(label, style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          /// Main content area
          Expanded(
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF800020),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  width: double.infinity,
                  child: Row(
                    children: [
                      const Icon(Icons.dashboard_customize, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Admin: $selectedTab',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.all(12),
                    child: currentWidget,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Icon _getIconForLabel(String label) {
    switch (label) {
      case 'Approve Sellers':
      case 'Approve Landlords':
        return const Icon(Icons.verified_user);
      case 'Ban Sellers':
      case 'Ban Landlords':
        return const Icon(Icons.person_off);
      case 'Pending Properties':
        return const Icon(Icons.home_work_outlined);
      case 'Reminders':
        return const Icon(Icons.notifications);
      case 'Orders':
        return const Icon(Icons.list_alt);
      case 'Refunds':
        return const Icon(Icons.money_off);
      case 'Products':
        return const Icon(Icons.shopping_bag);
      case 'Stats':
        return const Icon(Icons.bar_chart);
      case 'Complaints':
        return const Icon(Icons.report_problem);
      case 'Feedback':
        return const Icon(Icons.feedback);
      case 'Stores':
        return const Icon(Icons.store);
      case 'Create BuyNest Job':
        return const Icon(Icons.work_outline);
      default:
        return const Icon(Icons.dashboard);
    }
  }
}
