import 'package:flutter/material.dart';
import '../global/auth_data.dart';
import '../screens/store_setup_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/seller_bargains_screen.dart';
import '../screens/seller/seller_orders_screen.dart';
import '../screens/seller/seller_orders_tracking_screen.dart';
import '../screens/seller/promo_screen.dart';
import '../screens/seller/seller_complaints.dart';
import '../screens/seller/create_group_buy_screen.dart';
import '../screens/seller/seller_group_buys_screen.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/seller_order_service.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  String selectedTab = 'Dashboard';
  Map<String, dynamic>? sellerData;
  bool isLoading = true;

  List<Product>? recentProducts;
  List<Order>? recentOrders;
  bool isLoadingProducts = true;
  bool isLoadingOrders = true;

  late final Map<String, Widget Function()> tabViews;

  @override
  void initState() {
    super.initState();
    fetchSellerProfile();
    fetchRecentProducts();
    fetchRecentOrders();

    tabViews = {
      'Dashboard': () => buildDashboardTab(),
      'Store Setup': () => const StoreSetupScreen(),
      'Products': () => const ProductListScreen(),
      'Bargains': () => SellerBargainsScreen(sellerAuthToken: AuthData.token),
      'Orders': () => SellerOrdersScreen(sellerId: AuthData.sellerId, token: AuthData.token),
      'Track': () => SellerOrdersTrackingScreen(sellerId: AuthData.sellerId, token: AuthData.token),
      'Promos': () => const PromoScreen(),
      'Complaints': () => const SellerComplaintsScreen(),
      'Group Buys': () => const SellerGroupBuysScreen(),
      'Create Group Buy': () => const CreateGroupBuyScreen(),
      'Logout': () => const Center(child: Text('Logging out...')),
    };
  }

  Future<void> fetchSellerProfile() async {
    try {
      final data = await getSellerProfile(); // your existing function
      if (data != null) {
        setState(() {
          sellerData = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching seller profile: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchRecentProducts() async {
    if (AuthData.sellerId.isEmpty) {
      setState(() {
        isLoadingProducts = false;
        recentProducts = [];
      });
      return;
    }
    try {
      final products = await ProductService.fetchLatestProductsBySeller(AuthData.sellerId);
      setState(() {
        recentProducts = products;
        isLoadingProducts = false;
      });
    } catch (e) {
      print('Error fetching recent products: $e');
      setState(() {
        recentProducts = [];
        isLoadingProducts = false;
      });
    }
  }

  Future<void> fetchRecentOrders() async {
  if (AuthData.sellerId.isEmpty) {
    setState(() {
      isLoadingOrders = false;
      recentOrders = <Order>[];
    });
    return;
  }

  try {
    final List<Order> orders = await SellerOrderService.fetchSellerOrders(
      AuthData.sellerId,
      AuthData.token,
      limit: 3,
    );
    setState(() {
      recentOrders = orders;
      isLoadingOrders = false;
    });
  } catch (e) {
    print('Error fetching recent orders: $e');
    setState(() {
      recentOrders = <Order>[];
      isLoadingOrders = false;
    });
  }
}


  void handleLogout() {
    AuthData.token = '';
    AuthData.sellerId = '';
    AuthData.username = '';
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final sideTabs = tabViews.keys.toList();
    final currentWidget = tabViews[selectedTab]!();

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: sideTabs.indexOf(selectedTab),
            onDestinationSelected: (int index) {
              final label = sideTabs[index];
              if (label == 'Logout') {
                handleLogout();
              } else {
                setState(() => selectedTab = label);
              }
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                children: const [
                  Icon(Icons.storefront, size: 32),
                  SizedBox(height: 10),
                ],
              ),
            ),
            destinations: sideTabs
                .map((label) => NavigationRailDestination(
                      icon: _getIconForLabel(label),
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  width: double.infinity,
                  child: Row(
                    children: [
                      const Icon(Icons.dashboard_customize, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Seller: $selectedTab',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
          )
        ],
      ),
    );
  }

  Widget buildDashboardTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sellerData == null) {
      return const Center(child: Text('Failed to load seller data.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back, ${sellerData!['name'] ?? 'Seller'}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          _buildInfoCard('Phone', sellerData!['phone'] ?? 'N/A'),
          _buildInfoCard('Location', sellerData!['location'] ?? 'N/A'),
          _buildInfoCard('Occupation', sellerData!['occupation'] ?? 'N/A'),
          _buildInfoCard(
            'Approval Status',
            sellerData!['approved'] == true ? '✅ Approved' : '⏳ Pending Approval',
            bgColor: sellerData!['approved'] == true ? Colors.green.shade50 : Colors.orange.shade50,
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Products', '${sellerData!['productCount'] ?? '0'}',
                  Icons.list_alt, Colors.indigo),
              _buildStatCard('Orders', '${sellerData!['orderCount'] ?? '0'}',
                  Icons.shopping_bag, Colors.green),
              _buildStatCard('Earnings', '₦${sellerData!['earnings'] ?? '0'}',
                  Icons.monetization_on, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Recent Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (isLoadingProducts)
            const Center(child: CircularProgressIndicator())
          else if (recentProducts == null || recentProducts!.isEmpty)
            const Text('No recent products found.')
          else
            ...recentProducts!.map((p) => _buildProductPreview(p.name, '₦${p.price.toStringAsFixed(0)}')),

          const SizedBox(height: 24),

          const Text('Recent Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (isLoadingOrders)
            const Center(child: CircularProgressIndicator())
          else if (recentOrders == null || recentOrders!.isEmpty)
            const Text('No recent orders found.')
          else
            ...recentOrders!.map((o) {
              final totalItems = o.products.fold<int>(0, (sum, item) => sum + item.quantity);
              final totalPrice = o.products.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
              return _buildOrderPreview(o.orderId, '$totalItems item${totalItems > 1 ? 's' : ''}', '₦${totalPrice.toStringAsFixed(0)}');
            }),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, {Color? bgColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Text('$title: ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Icon _getIconForLabel(String label) {
    switch (label) {
      case 'Dashboard':
        return const Icon(Icons.dashboard);
      case 'Store Setup':
        return const Icon(Icons.store);
      case 'Products':
        return const Icon(Icons.list_alt);
      case 'Bargains':
        return const Icon(Icons.handshake);
      case 'Orders':
        return const Icon(Icons.shopping_bag);
      case 'Track':
        return const Icon(Icons.track_changes);
      case 'Promos':
        return const Icon(Icons.local_offer);
      case 'Complaints':
        return const Icon(Icons.report);
      case 'Group Buys':
        return const Icon(Icons.manage_accounts);
      case 'Create Group Buy':
        return const Icon(Icons.groups);
      case 'Logout':
        return const Icon(Icons.logout);
      default:
        return const Icon(Icons.dashboard);
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductPreview(String name, String price) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.inventory_2, color: Colors.indigo),
        title: Text(name),
        subtitle: Text(price),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildOrderPreview(String orderId, String items, String total) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.green),
        title: Text(orderId),
        subtitle: Text(items),
        trailing: Text(total, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
