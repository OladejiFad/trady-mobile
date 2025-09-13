import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../services/tracking_service.dart';
import '../../services/bargain_service.dart';
import '../../services/complaint_service.dart';
import '../../services/cart_service.dart';


import '../../utils/image_utils.dart';

import '../../models/complaint_model.dart';
import '../../models/bargain_model.dart';
import '../../helpers/status_color_helper.dart';
import '../../global/auth_data.dart';
import '../../main.dart'; // For Routes

final String backendBaseUrl = 'http://172.20.10.2:5000';

class EnhancedTrackingScreen extends StatelessWidget {
  const EnhancedTrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          accentColor: Colors.amber,
          backgroundColor: Colors.grey[100],
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.grey[800],
                displayColor: Colors.grey[800],
              ),
        ),
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          surfaceTintColor: Colors.white,
          shadowColor: Colors.teal.withOpacity(0.2),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
            shadowColor: Colors.teal.withOpacity(0.3),
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey[600],
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: Colors.teal, width: 3),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          filled: true,
          fillColor: Colors.teal.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      child: const TrackingScreen(),
    );
  }
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  String? errorMessage;
  Map<String, dynamic>? trackingData;
  bool isLoading = false;
  List<Complaint> complaints = [];
  List<Bargain> _successfulBargains = [];
  final Set<String> _addedBargainIds = {};
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  late TabController _tabController;
  final CartService _cartService = CartService();
  final BargainService _bargainService = BargainService(buyerAuthToken: AuthData.token);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('buyerPhone');
    final savedToken = prefs.getString('buyerToken');

    if (savedToken != null) {
      AuthData.token = savedToken;
    }

    if (savedPhone != null) {
      _phoneController.text = savedPhone;
   await _track();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a phone number';
        trackingData = null;
        complaints = [];
        _successfulBargains = [];
        isLoadingNotifier.value = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      isLoadingNotifier.value = true;
      errorMessage = null;
      trackingData = null;
      complaints = [];
      _successfulBargains = [];
    });

    try {
      final data = await TrackingService.trackByBuyer(phone);
      final complaintList = await ComplaintService.getComplaintsByUser(phone);
      final List<Bargain> successfulData = await BargainService().getSuccessfulBargains(phone);
      final List<Bargain> successful = successfulData;

      for (var b in successful) {
        print('✅ Bargain ID: ${b.id}, Status: ${b.status}, AcceptedPrice: ${(b.acceptedPrice ?? 0.0).toStringAsFixed(2)}, Added: ${b.addedToCart}');
      }

      _successfulBargains = successful;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('buyerPhone', phone);
      AuthData.buyerPhone = phone;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome back, $phone!')),
      );

      setState(() {
        trackingData = data;
        complaints = complaintList;
        _successfulBargains = successful;
      });
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() {
        isLoading = false;
        isLoadingNotifier.value = false;
      });
    }
  }

  void _addToCart(Bargain bargain, List<BargainItem> items, double price) async {
    final bargainId = bargain.id;
    final productId = bargain.productIds.isNotEmpty ? bargain.productIds.first : null;
    final sellerId = bargain.sellerId;

    if (bargainId.isEmpty || productId == null || sellerId.isEmpty) {
      print("Missing data");
      return;
    }

    if (items.isEmpty) {
      print("No accepted items found for bargain ${bargain.id}");
      return;
    }

    final item = items.first;

    _cartService.addToCart(
      productId: productId,
      sellerId: sellerId,
      productName: item.productName,
      imageUrl: item.imageUrl,
      price: item.productPrice,
      quantity: item.quantity,
      isBargain: true,
      bargainId: bargain.id,
    );

    if (AuthData.buyerPhone == null || AuthData.buyerPhone!.isEmpty) {
      print("Buyer phone is missing");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing buyer phone")),
      );
      return;
    }

    bool success = false;
    try {
      success = await _bargainService.addToCartFromBargain(
        bargainId: bargainId,
        buyerPhone: AuthData.buyerPhone,
      );
    } catch (e) {
      print('Error adding bargain to cart on backend: $e');
    }

    if (success) {
      setState(() {
        _addedBargainIds.add(bargain.id);
        _successfulBargains.removeWhere((b) => b.id == bargainId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bargain added to cart successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add bargain to cart on server.')),
      );
    }
  }

  Widget _buildBargainTab() {
    if (_successfulBargains.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handshake_outlined, size: 60, color: Colors.teal.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No successful bargains yet. Try tracking again.',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _successfulBargains.length,
      itemBuilder: (_, i) {
        final b = _successfulBargains[i];

        final allOffers = [
          ...b.buyerOffers.map((o) => {
                'price': o.totalOfferedPrice,
                'items': o.items,
                'time': o.time,
              }),
          ...b.sellerOffers.map((o) => {
                'price': o.totalCounterPrice,
                'items': o.items,
                'time': o.time,
              }),
        ];

        allOffers.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

        final matchedOffer = allOffers.firstWhere(
          (offer) => (offer['price'] as double).toStringAsFixed(2) == (b.acceptedPrice ?? 0.0).toStringAsFixed(2),
          orElse: () => allOffers.isNotEmpty ? allOffers.last : {'items': <BargainItem>[], 'price': 0.0},
        );

        final List<BargainItem> acceptedItems = matchedOffer['items'] as List<BargainItem>;
        final double acceptedPrice = matchedOffer['price'] as double;

        if (acceptedItems.isEmpty) {
          print("No accepted items found for bargain ${b.id}");
          return const SizedBox();
        }

        final item = acceptedItems.first;
        final unitPrice = item.productPrice;
        final quantity = item.quantity;

        String imageUrl = item.imageUrl ?? '';
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          if (imageUrl.startsWith('/')) {
            imageUrl = backendBaseUrl + imageUrl;
          } else {
            imageUrl = '$backendBaseUrl/$imageUrl';
          }
        }

        final name = item.productName;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          child: ListTile(
            leading: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  )
                : const Icon(Icons.image_not_supported, size: 50),
            title: Text(name),
            subtitle: Text(
              'Accepted Total: ₦${acceptedPrice.toStringAsFixed(2)}\n(${unitPrice.toStringAsFixed(2)} x $quantity)',
            ),
            trailing: _addedBargainIds.contains(b.id)
                ? const Chip(label: Text('In Cart'), backgroundColor: Colors.grey)
                : AnimatedButton(
                    onPressed: () => _addToCart(b, acceptedItems, acceptedPrice),
                    child: ElevatedButton(
                      onPressed: () => _addToCart(b, acceptedItems, acceptedPrice),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Add to Cart'),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRowWidget(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTab() {
    final orders = trackingData?['orders'] ?? [];
    if (orders.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.teal.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No orders found.',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        final products = (o['products'] as List)
            .map((p) => '• ${p['quantity']} x ${p['productId']} @ ₦${p['price']}')
            .join('\n');

        final createdAtRaw = o['createdAt'];
        final createdAtFormatted = createdAtRaw != null && createdAtRaw.isNotEmpty
            ? DateFormat.yMMMd()
                .add_jm()
                .format(DateTime.tryParse(createdAtRaw)?.toLocal() ?? DateTime.now())
            : 'Unknown';

        final paymentStatus = o['paymentStatus'] ?? 'pending';
        final shipmentStatus = o['shipmentStatus'] ?? 'pending';
        String satisfactionStatus = o['satisfactionStatus'] ?? 'pending';
        final orderStatus = o['orderStatus'] ?? 'pending';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🧾 Order ID: ${o['orderId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('👤 ${o['buyerName']} (${o['buyerPhone']})'),
                Text('📍 ${o['buyerLocation']}'),
                const SizedBox(height: 6),
                Text(products),
                const Divider(),
                _buildStatusRowWidget('💰 Payment Status:', StatusColorHelper.paymentLabel(paymentStatus),
                    StatusColorHelper.paymentColor(paymentStatus)),
                const SizedBox(height: 8),
                _buildStatusRowWidget('📦 Shipment Status:', StatusColorHelper.shipmentLabel(shipmentStatus),
                    StatusColorHelper.shipmentColor(shipmentStatus)),
                const SizedBox(height: 8),
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text('🙂 Satisfaction:', style: TextStyle(fontWeight: FontWeight.bold)),
    satisfactionStatus == 'Unrated'
        ? PopupMenuButton<String>(
            tooltip: 'Update satisfaction status',
            onSelected: (value) async {
              setState(() => satisfactionStatus = value);
              try {
                await TrackingService.updateSatisfactionStatus(o['orderId'], value, AuthData.token);
                await _track();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Satisfaction updated')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Satisfied ❤', child: Text('Satisfied ❤')),
              PopupMenuItem(value: 'I Like It 💛', child: Text('I Like It 💛')),
              PopupMenuItem(value: 'Refund', child: Text('Refund')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: StatusColorHelper.satisfactionColor(satisfactionStatus),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                StatusColorHelper.satisfactionLabel(satisfactionStatus),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: StatusColorHelper.satisfactionColor(satisfactionStatus),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              StatusColorHelper.satisfactionLabel(satisfactionStatus),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
  ],
),

           
                const SizedBox(height: 12),
                _buildStatusRowWidget('📝 Order Status:', StatusColorHelper.orderStatusLabel(orderStatus),
                    StatusColorHelper.orderStatusColor(orderStatus)),
                const SizedBox(height: 12),
                Text('📅 Created: $createdAtFormatted', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComplaintsTab() {
    if (complaints.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_outlined, size: 60, color: Colors.teal.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No complaints found.',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: complaints.length,
      itemBuilder: (_, i) {
        final c = complaints[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text('📢 ${c.subject}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.description),
                if (c.response != null) ...[
                  const SizedBox(height: 8),
                  Text('💬 Admin response: ${c.response!}', style: const TextStyle(color: Colors.green)),
                ],
                const SizedBox(height: 4),
                Text(
                  '📅 ${DateFormat.yMMMd().add_jm().format(c.createdAt?.toLocal() ?? DateTime.now())}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              //START
              SliverAppBar(
  expandedHeight: 150.0,
  floating: false,
  pinned: true,
  centerTitle: true,
  flexibleSpace: FlexibleSpaceBar(
    centerTitle: true,
    title: Padding(
      padding: EdgeInsets.only(bottom: 46), // <--- Adjust this value as needed
      child: const Text(
        'Track Orders & Bargains',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ),
    background: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.tealAccent.shade400, Colors.teal.shade700],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    ),
  ),
  bottom: trackingData != null
      ? TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag, color: Colors.white), text: 'Orders'),
            Tab(icon: Icon(Icons.handshake, color: Colors.white), text: 'Bargains'),
            Tab(icon: Icon(Icons.warning, color: Colors.white), text: 'Complaints'),
          ],
        )
      : null,
),


  //END

              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade50, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(90),
                    child: Column(
                      children: [
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Enter phone number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
  onPressed: isLoading
      ? null
      : () {
          _track(); // call the async function
        },
  icon: const Icon(Icons.search),
  label: isLoading
      ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : const Text('Track'),
),



                        

                        
                        const SizedBox(height: 12),
                        if (errorMessage != null) Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        if (trackingData != null)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                            child: SizedBox(
                              key: ValueKey<int>(_tabController.index),
                              height: MediaQuery.of(context).size.height - 300,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildOrderTab(),
                                  _buildBargainTab(),
                                  _buildComplaintsTab(),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, size: 60, color: Colors.teal.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'Enter your phone number and tap Track',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLoadingNotifier,
            builder: (context, isLoading, child) {
              return isLoading
                  ? Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: trackingData != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedButton(
                onPressed: () => Navigator.pushNamed(context, Routes.buyerOrders),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, Routes.buyerOrders),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('View My Orders'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              ),
            )
          : null,
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const AnimatedButton({required this.onPressed, required this.child, Key? key}) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}