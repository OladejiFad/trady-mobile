import 'package:flutter/material.dart';
import '../../global/auth_data.dart';
import '../../widgets/property/property_card.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import 'add_property_screen.dart';
import 'package:trady_mobile/screens/landlord/landlord_messages_screen.dart';
import 'package:trady_mobile/screens/landlord/landlord_chat_screen.dart';


class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  State<LandlordDashboardScreen> createState() => _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  String selectedTab = 'My Properties';
  List<Property> myProperties = [];
  bool isLoading = true;
  String? error;

  final Map<String, Widget Function()> tabViews = {};

  @override
  void initState() {
    super.initState();
    fetchMyProperties();

    tabViews.addAll({
      'My Properties': () => buildMyPropertiesTab(),
      'Add Property': () => const AddPropertyScreen(),
      'Messages': () => const LandlordMessagesScreen(),
      'Complaints': () => const Center(child: Text('📢 Complaints coming soon')),
      'Transactions': () => const Center(child: Text('💰 Transactions coming soon')),
      'Logout': () => const Center(child: Text('Logging out...')),
    });
  }

  Future<void> fetchMyProperties() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await PropertyService().fetchPropertiesByLandlord(AuthData.landlordId!);
      setState(() {
        myProperties = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Widget buildMyPropertiesTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      return Center(child: Text('Error: $error'));
    } else if (myProperties.isEmpty) {
      return const Center(child: Text('No properties found'));
    } else {
      return ListView.builder(
        itemCount: myProperties.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final property = myProperties[index];
          return PropertyCard(
            property: property,
            onMessageLandlord: () {},
            onEdit: () {
              // Add edit navigation here if needed
            },
          );
        },
      );
    }
  }

  void handleLogout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      AuthData.token = '';
      AuthData.landlordId = '';
      AuthData.username = '';
      Navigator.pushReplacementNamed(context, '/login');
    });
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
                  Icon(Icons.house, size: 32),
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
                        'Landlord: $selectedTab',
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

  Icon _getIconForLabel(String label) {
    switch (label) {
      case 'My Properties':
        return const Icon(Icons.home_work);
      case 'Add Property':
        return const Icon(Icons.add_home_work);
      case 'Messages':
        return const Icon(Icons.message);
      case 'Complaints':
        return const Icon(Icons.report);
      case 'Transactions':
        return const Icon(Icons.attach_money);
      case 'Logout':
        return const Icon(Icons.logout);
      default:
        return const Icon(Icons.dashboard);
    }
  }
}
