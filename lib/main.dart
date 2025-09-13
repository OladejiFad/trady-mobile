import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Login/Register
import 'screens/login_page.dart';
import 'screens/register_page.dart';

// Seller
import 'screens/seller_dashboard.dart';
import 'screens/store_setup_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/seller/seller_group_buys_screen.dart';

// Buyer
import 'screens/buyer_product_list_screen.dart';
import 'screens/buyer_product_detail_screen.dart';
import 'screens/buyer/buyer_orders_screen.dart';
import 'screens/buyer/buyer_store_screen.dart';
import 'screens/buyer/store_detail_screen.dart';
import 'screens/buyer/group_buy_market_screen.dart';

// Bargain
import 'screens/send_bargain_screen.dart';
import 'screens/buyer_bargains_screen.dart';
import 'screens/seller_bargains_screen.dart';

// Tracking
import 'screens/buyer/tracking_screen.dart';

// Admin
import 'screens/admin/admin_auth_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

// Landlord
import 'screens/landlord/landlord_dashboard_screen.dart';
import 'screens/property/property_list_screen.dart';
import 'screens/transaction/transaction_list_screen.dart';
import 'screens/landlord/add_property_screen.dart';

// Chat Screens
import 'screens/buyer/buyer_chat_screen.dart';
import 'screens/landlord/landlord_chat_screen.dart';
import 'screens/landlord/landlord_messages_screen.dart';

// Public / Trady Jobs
import 'screens/public/trady_jobs_screen.dart';

// Globals
import 'global/auth_data.dart';
import 'global/admin_auth_data.dart';

// Models
import 'models/store_model.dart';

// Services
import 'services/cart_service.dart';

final CartService cartService = CartService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  AdminAuthData.token = prefs.getString('adminToken') ?? '';
  AdminAuthData.adminId = prefs.getString('adminId') ?? '';
  AdminAuthData.username = prefs.getString('adminUsername') ?? '';

  AuthData.buyerPhone = prefs.getString('buyerPhone') ?? '';

  runApp(const MyApp());
}

class Routes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const storeSetup = '/store-setup';
  static const products = '/products';
  static const addProduct = '/add-product';
  static const productDetail = '/product-detail';
  static const sendBargain = '/send-bargain';
  static const buyerBargains = '/buyer-bargains';
  static const sellerBargains = '/seller-bargains';
  static const buyerOrders = '/buyer-orders';
  static const tracking = '/tracking';
  static const buyerStore = '/buyer-store';
  static const storeDetail = '/store-detail';
  static const groupBuyMarket = '/group-buy-market';
  static const sellerGroupBuys = '/seller/group-buys';

  // Admin
  static const adminAuth = '/admin/auth';
  static const adminDashboard = '/admin/dashboard';

  // Landlord
  static const landlordDashboard = '/landlord-dashboard';
  static const landlordProperties = '/landlord/properties';
  static const landlordMessages = '/landlord/messages';
  static const landlordTransactions = '/landlord/transactions';
  static const addProperty = '/landlord/add-property';

  // Buyer-accessible properties
  static const properties = '/properties';
  static const messages = '/messages';

  // Public Trady Jobs
  static const tradyJobs = '/trady-jobs';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuyNest App',
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.home,
      routes: {
        Routes.home: (context) => BuyerProductListScreen(),
        Routes.login: (context) => const LoginPage(),
        Routes.register: (context) => const RegisterPage(),
        Routes.dashboard: (context) => const SellerDashboard(),
        Routes.storeSetup: (context) => const StoreSetupScreen(),
        Routes.products: (context) => ProductListScreen(),
        Routes.addProduct: (context) => const AddProductScreen(),
        Routes.buyerOrders: (context) => const BuyerOrdersScreen(),
        Routes.adminAuth: (context) => const AdminAuthScreen(),
        Routes.adminDashboard: (context) => const AdminDashboardScreen(),
        Routes.tracking: (context) => const TrackingScreen(),
        Routes.landlordDashboard: (context) => const LandlordDashboardScreen(),
        Routes.landlordProperties: (context) => const PropertyListScreen(),
        Routes.addProperty: (context) => const AddPropertyScreen(),
        Routes.landlordTransactions: (context) => const TransactionListScreen(),
        Routes.properties: (context) => const PropertyListScreen(),
        Routes.tradyJobs: (context) => const TradyJobsScreen(),
        Routes.groupBuyMarket: (context) => const GroupBuyMarketScreen(),
        Routes.sellerGroupBuys: (context) => const SellerGroupBuysScreen(),
      },
      onGenerateRoute: (settings) {
        print('Navigating to: ${settings.name}');

        switch (settings.name) {
          case Routes.landlordMessages:
            return MaterialPageRoute(
              builder: (_) => const LandlordMessagesScreen(),
            );

          case Routes.messages:
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null &&
                args['chatPartnerId'] != null &&
                args['chatPartnerName'] != null &&
                args['propertyId'] != null) {
              return MaterialPageRoute(
                builder: (_) => BuyerChatScreen(
                  landlordId: args['chatPartnerId'] as String,
                  landlordName: args['chatPartnerName'] as String,
                  propertyId: args['propertyId'] as String,
                ),
              );
            }
            return _errorRoute("Missing chatPartnerId, chatPartnerName, or propertyId.");

          case Routes.productDetail:
            final productId = settings.arguments as String?;
            if (productId != null) {
              return MaterialPageRoute(
                builder: (_) => BuyerProductDetailScreen(productId: productId),
              );
            }
            return _errorRoute("Missing product ID.");

          case Routes.sendBargain:
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args['productIds'] is List<String>) {
              return MaterialPageRoute(
                builder: (_) => SendBargainScreen(productIds: args['productIds']),
              );
            }
            return _errorRoute("Missing or invalid arguments for Send Bargain.");

          case Routes.buyerBargains:
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args['buyerPhone'] != null) {
              return MaterialPageRoute(
                builder: (_) => BuyerBargainsScreen(buyerPhone: args['buyerPhone']),
              );
            }
            return _errorRoute("Missing buyer phone.");

          case Routes.sellerBargains:
            return MaterialPageRoute(
              builder: (_) => SellerBargainsScreen(sellerAuthToken: AuthData.token),
            );

          case Routes.buyerStore:
            return MaterialPageRoute(
              builder: (_) => const BuyerStoreScreen(),
            );

          case Routes.storeDetail:
            final store = settings.arguments as Store?;
            if (store != null) {
              return MaterialPageRoute(
                builder: (_) => StoreDetailScreen(store: store),
              );
            }
            return _errorRoute("Missing store data.");

          default:
            return _errorRoute("Route not found: ${settings.name}");
        }
      },
    );
  }

  Route _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Text(message)),
      ),
    );
  }
}
