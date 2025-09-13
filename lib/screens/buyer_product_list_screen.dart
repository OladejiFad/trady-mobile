import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/complaint_service.dart';
import '../../models/complaint_model.dart';
import '../../main.dart';
import 'cart_screen.dart';
import '../../models/group_buy_model.dart';
import '../../services/group_buy_service.dart';
import '../../global/auth_data.dart';
import 'buyer_bargains_screen.dart';
import '../../services/market_service.dart';
import '../../widgets/market_day_banner.dart';
import '../../widgets/product_sizes_colors.dart';

class BuyerProductListScreen extends StatefulWidget {
  final String? sellerId;
  const BuyerProductListScreen({Key? key, this.sellerId}) : super(key: key);

  @override
  State<BuyerProductListScreen> createState() => _BuyerProductListScreenState();
}

class _BuyerProductListScreenState extends State<BuyerProductListScreen> with SingleTickerProviderStateMixin {
  late Future<List<Product>> _productsFuture;
  late Future<List<GroupBuy>> _groupBuysFuture;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Set<String> _selectedProductIds = {};
  final CartService _cartService = CartService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦');
  final ScrollController _scrollController = ScrollController();
  Timer? _autoRefreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isMarketDay = false;

  @override
  void initState() {
    super.initState();
    _checkMarketDay();
    _productsFuture = _fetchProducts();
    _groupBuysFuture = widget.sellerId != null
        ? GroupBuyService.fetchGroupBuysBySeller(widget.sellerId!)
        : GroupBuyService().fetchAllGroupBuys();

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {
        _groupBuysFuture = widget.sellerId != null
            ? GroupBuyService.fetchGroupBuysBySeller(widget.sellerId!)
            : GroupBuyService().fetchAllGroupBuys();
        _checkMarketDay();
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  Future<void> _checkMarketDay() async {
    final isMarketDay = await MarketService.fetchMarketDayStatus('buyer');

    setState(() {
      _isMarketDay = isMarketDay;
      _filterProducts();
    });
  }

  Future<List<Product>> _fetchProducts() async {
    try {
      List<Product> fetchedProducts;

      if (widget.sellerId != null) {
        fetchedProducts = await ProductService.fetchProductsBySeller(widget.sellerId!);
      } else {
        fetchedProducts = await ProductService.fetchFilteredProducts();
      }

      setState(() {
        _allProducts = fetchedProducts;
        _filterProducts();
      });

      return fetchedProducts;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToMyBargains() async {
    String phone = AuthData.buyerPhone;

    if (phone.isEmpty) {
      final input = await _showPhoneInputDialog();
      if (input == null || input.trim().isEmpty) return;

      phone = input.trim();
      AuthData.buyerPhone = phone;
      await AuthData.save();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerBargainsScreen(buyerPhone: phone),
      ),
    );
  }

  Future<String?> _showPhoneInputDialog() async {
    String input = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text('Enter Phone Number', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          keyboardType: TextInputType.phone,
          onChanged: (value) => input = value,
          decoration: InputDecoration(
            hintText: 'e.g. 08123456789',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.phone, color: Colors.deepPurple),
          ),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, input),
            child: Text('Continue', style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width >= 1920) return 10;
    if (width >= 1400) return 8;
    if (width >= 1200) return 6;
    if (width >= 975) return 5;
    if (width >= 768) return 4;
    if (width >= 320) return 2;
    return 1;
  }

  double _calculateAspectRatio(double width) {
    if (width >= 1400) return 0.65;
    if (width >= 768) return 0.60;
    if (width >= 320) return 0.55;
    return 0.50;
  }

  double _calculateImageAspectRatio(double width) {
    if (width >= 1400) return 1.3;
    if (width >= 768) return 1.2;
    return 1.1;
  }

  int _calculateMaxChips(double width) {
    if (width >= 1400) return 5;
    if (width >= 768) return 4;
    return 3;
  }

  void _toggleSelection(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _startBargain() {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one product to bargain.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final selectedProducts = _allProducts.where((p) => _selectedProductIds.contains(p.id)).toList();
    final sellerId = selectedProducts.first.sellerId;

    Navigator.pushNamed(
      context,
      Routes.sendBargain,
      arguments: {
        'productIds': _selectedProductIds.toList(),
        'sellerId': sellerId,
        'buyerName': 'guest_buyer',
      },
    );
  }

  void _goToTracking() {
    Navigator.pushNamed(context, Routes.tracking);
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
        final matchSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchMarketDay = !_isMarketDay || (product.marketSection != null);
        return matchCategory && matchSearch && matchMarketDay;
      }).toList();
    });
  }

  List<String> get _uniqueCategories {
    final categories = _allProducts
        .where((p) => !_isMarketDay || (p.marketSection != null))
        .map((p) => p.category)
        .toSet()
        .toList();
    categories.sort();
    return ['All', ...categories];
  }

  void _addToCart(Product product) {
    _cartService.addToCart(
      productId: product.id,
      productName: product.name,
      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
      price: product.price,
      sellerId: product.sellerId,
      quantity: 1,
    );

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showComplaintDialog() {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Text('Make Complaint', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: 'Complaint Subject',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.subject, color: Colors.deepPurple),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Complaint Description',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.description, color: Colors.deepPurple),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Your Phone Number',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.phone, color: Colors.deepPurple),
                  ),
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final subject = subjectController.text.trim();
                      final description = descriptionController.text.trim();
                      final phone = phoneController.text.trim();

                      if (subject.isEmpty || description.isEmpty || phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('All fields are required', style: GoogleFonts.poppins()),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        await ComplaintService.createComplaint(
                          token: 'YOUR_AUTH_TOKEN',
                          subject: subject,
                          description: description,
                          buyerPhone: phone,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Complaint submitted successfully!', style: GoogleFonts.poppins()),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to submit complaint: $e', style: GoogleFonts.poppins()),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple),
                    )
                  : Text('Submit', style: GoogleFonts.poppins(color: Colors.deepPurple)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSilverTitle(String text) {
    return GestureDetector(
      onLongPress: () {
        Navigator.pushNamed(context, Routes.adminAuth);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB0BEC5), Color(0xFFECEFF1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
            BoxShadow(color: Colors.white70, blurRadius: 6, offset: Offset(-2, -2)),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _joinGroup(GroupBuy groupBuy) async {
    final nameController = TextEditingController(text: AuthData.buyerName);
    final phoneController = TextEditingController(text: AuthData.buyerPhone);
    final qtyController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text('Join: ${groupBuy.title}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                  ),
                  style: GoogleFonts.poppins(),
                  validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.phone, color: Colors.deepPurple),
                  ),
                  style: GoogleFonts.poppins(),
                  validator: (val) => val == null || val.isEmpty ? 'Enter your phone' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.numbers, color: Colors.deepPurple),
                  ),
                  style: GoogleFonts.poppins(),
                  validator: (val) {
                    final qty = int.tryParse(val ?? '');
                    if (qty == null || qty <= 0) return 'Enter valid quantity';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            child: Text('Join', style: GoogleFonts.poppins(color: Colors.white)),
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              try {
                final participant = GroupParticipant(
                  name: nameController.text,
                  phone: phoneController.text,
                  quantity: int.parse(qtyController.text),
                );
                await GroupBuyService().joinGroupBuy(
                  groupId: groupBuy.id,
                  participant: participant,
                );
                Navigator.pop(context);
                if (mounted) {
                  setState(() {
                    _groupBuysFuture = GroupBuyService().fetchAllGroupBuys();
                  });
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Joined successfully', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);
    final childAspectRatio = _calculateAspectRatio(screenWidth);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: Image.asset(
  'assets/logo.jpg',
  height: 62,
),


        backgroundColor: Colors.deepPurple.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.local_offer, color: Colors.white, size: 28),
            tooltip: 'My Bargains',
            onPressed: _navigateToMyBargains,
          ),
          IconButton(
            icon: const Icon(Icons.report_problem, color: Colors.redAccent, size: 28),
            onPressed: _showComplaintDialog,
            tooltip: 'Report a Complaint',
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(cartService: _cartService),
                    ),
                  ).then((_) => setState(() {}));
                },
                tooltip: 'Cart',
              ),
              if (_cartService.localCart.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: _StyledBadge(
                    text: '${_cartService.localCart.length}',
                    color: Colors.redAccent,
                    fontSize: 12,
                    padding: const EdgeInsets.all(6),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.store, color: Colors.white, size: 28),
            tooltip: 'Visit Store',
            onPressed: () {
              if (_filteredProducts.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  Routes.buyerStore,
                  arguments: _filteredProducts.first.sellerId,
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        width: 280,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(20))),
        elevation: 8,
        child: Column(
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade700, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Hero(
                      tag: 'user_avatar',
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.person, color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Shopper!',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Discover Great Deals',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.track_changes,
                    title: 'Order Tracking',
                    onTap: () {
                      Navigator.pop(context);
                      _goToTracking();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.home_work_outlined,
                    title: 'Properties',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.properties);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.work_outline,
                    title: 'BuyNest Jobs',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.tradyJobs);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.shopping_cart,
                    title: 'Cart',
                    badgeCount: _cartService.localCart.length,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(cartService: _cartService),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.local_offer,
                    title: 'My Bargains',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMyBargains();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.login,
                    title: 'Login',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.login);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'BuyNest App v1.0',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder<List<GroupBuy>>(
          future: _groupBuysFuture,
          builder: (context, snapshot) {
            final groupBuySection = snapshot.hasData
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Group Buys You Can Join',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.deepPurple.shade900,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, Routes.groupBuyMarket);
                          },
                          child: Text(
                            'See All →',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox();

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarketDayBanner(role: 'buyer', color: const Color(0xFFE5F5E0)),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFB0C4DE),
                            Color(0xFF99AEDC),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Text(
                        _isMarketDay
                            ? 'Market Day Exclusive Deals!'
                            : 'Use WELCOME5 to get ₦500 off your first order!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  groupBuySection,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Search Products',
                              labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                              prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                            ),
                            style: GoogleFonts.poppins(),
                            onChanged: (value) {
                              _searchQuery = value;
                              _filterProducts();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            items: _uniqueCategories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category, style: GoogleFonts.poppins()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              _selectedCategory = value!;
                              _filterProducts();
                            },
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final isSelected = _selectedProductIds.contains(product.id);
                        final latestReview = product.reviews.isNotEmpty
                            ? product.reviews.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
                            : null;

                        return _SelectableCompactCard(
                          product: product,
                          selected: isSelected,
                          latestReview: latestReview,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.productDetail, arguments: product.id);
                          },
                          onSelectToggle: () => _toggleSelection(product.id),
                          onAddToCart: () => _addToCart(product),
                          currencyFormat: _currencyFormat,
                          imageAspectRatio: _calculateImageAspectRatio(screenWidth),
                          maxChips: _calculateMaxChips(screenWidth),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _selectedProductIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _startBargain,
              icon: const Icon(Icons.local_offer, size: 20),
              label: Text(
                'Bargain (${_selectedProductIds.length})',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.deepPurple.shade600, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount > 0)
                _StyledBadge(
                  text: '$badgeCount',
                  color: Colors.redAccent,
                  fontSize: 12,
                  padding: const EdgeInsets.all(8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyledBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final EdgeInsets padding;

  const _StyledBadge({
    required this.text,
    required this.color,
    required this.fontSize,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    final scaleFactor = MediaQuery.of(context).size.width < 576 ? 0.8 : 1.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: padding * scaleFactor,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4 * scaleFactor,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      constraints: BoxConstraints(minWidth: 20 * scaleFactor, minHeight: 20 * scaleFactor),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: fontSize * scaleFactor,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SelectableCompactCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onSelectToggle;
  final VoidCallback onAddToCart;
  final bool selected;
  final NumberFormat currencyFormat;
  final Review? latestReview;
  final double imageAspectRatio;
  final int maxChips;

  const _SelectableCompactCard({
    required this.product,
    required this.onTap,
    required this.onSelectToggle,
    required this.onAddToCart,
    required this.selected,
    required this.currencyFormat,
    this.latestReview,
    required this.imageAspectRatio,
    required this.maxChips,
  });

  @override
  State<_SelectableCompactCard> createState() => _SelectableCompactCardState();
}

class _SelectableCompactCardState extends State<_SelectableCompactCard>
    with SingleTickerProviderStateMixin {
  String? selectedSize;
  String? selectedColor;
  bool _isLoading = false;
  bool _isAdded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleAddToCart() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    widget.onAddToCart();

    setState(() {
      _isLoading = false;
      _isAdded = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isAdded = false;
      });
    }
  }

  Widget _buildStarRating(double rating) {
    const maxStars = 5;
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;
    final emptyStars = maxStars - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      children: [
        ...List.generate(fullStars, (_) => const Icon(Icons.star, size: 10, color: Colors.amber)),
        if (hasHalfStar) const Icon(Icons.star_half, size: 10, color: Colors.amber),
        ...List.generate(emptyStars, (_) => const Icon(Icons.star_border, size: 10, color: Colors.amber)),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.poppins(fontSize: 8, color: Colors.black87),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    print("🛒 ${product.name} has stock: ${product.stockQuantity}");
    final hasSizesOrColors = product.sizes.isNotEmpty || product.colors.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 576 ? 8.0 : 10.0;
    final buttonHeight = screenWidth < 576 ? 24.0 : 26.0;
    final isOutOfStock = product.stockQuantity != null ? product.stockQuantity! <= 0 : false;

    return MouseRegion(
      onEnter: (_) => _animationController.forward(),
      onExit: (_) => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: widget.selected ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 4,
          shadowColor: Colors.black12,
          borderOnForeground: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            onLongPress: widget.onSelectToggle,
            child: ClipRect(
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        aspectRatio: widget.imageAspectRatio,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: product.imageUrls.isNotEmpty
                              ? Hero(
                                  tag: 'product_${product.id}',
                                  child: Image.network(
                                    product.imageUrls.first.startsWith('http')
                                        ? product.imageUrls.first
                                        : 'http://172.20.10.2:5000${product.imageUrls.first}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize + 2,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepPurple.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              product.discount > 0
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.currencyFormat.format(product.price * (1 - product.discount / 100)),
                                          style: GoogleFonts.poppins(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        Text(
                                          widget.currencyFormat.format(product.price),
                                          style: GoogleFonts.poppins(
                                            fontSize: fontSize - 1,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                        _StyledBadge(
                                          text: '${product.discount.round()}% OFF',
                                          color: Colors.green.shade700,
                                          fontSize: fontSize - 1,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      widget.currencyFormat.format(product.price),
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                              const SizedBox(height: 2),
                              hasSizesOrColors
                                  ? ProductSizesColors(
                                      sizes: product.sizes.take(widget.maxChips).toList(),
                                      colors: product.colors.take(widget.maxChips).toList(),
                                      selectedSize: selectedSize,
                                      selectedColor: selectedColor,
                                      onSizeSelected: (size) {
                                        setState(() {
                                          selectedSize = size;
                                        });
                                        print("Selected Size: $size");
                                      },
                                      onColorSelected: (color) {
                                        setState(() {
                                          selectedColor = color;
                                        });
                                        print("Selected Color: $color");
                                      },
                                      fontSize: fontSize - 1,
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Category: ${product.category}',
                                          style: GoogleFonts.poppins(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        widget.latestReview != null
                                            ? _buildStarRating(widget.latestReview!.rating.toDouble())
                                            : Text(
                                                'No reviews yet',
                                                style: GoogleFonts.poppins(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ],
                                    ),
                              const SizedBox(height: 2),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _isLoading
                                    ? Center(
                                        child: SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple),
                                        ),
                                      )
                                    : _isAdded
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.green, size: 12),
                                              const SizedBox(width: 4),
                                              _StyledBadge(
                                                text: 'Added to Cart',
                                                color: Colors.green.shade700,
                                                fontSize: fontSize,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              ),
                                            ],
                                          )
                                        : isOutOfStock
                                            ? _StyledBadge(
                                                text: 'Out of Stock',
                                                color: Colors.grey.shade600,
                                                fontSize: fontSize,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              )
                                            : ElevatedButton.icon(
                                                key: const ValueKey('add_button'),
                                                onPressed: _handleAddToCart,
                                                icon: const Icon(Icons.add_shopping_cart, size: 12),
                                                label: Text(
                                                  'Add to Cart',
                                                  style: GoogleFonts.poppins(fontSize: fontSize),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.deepPurple,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: Size(double.infinity, buttonHeight),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  elevation: 1,
                                                ),
                                              ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isOutOfStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _StyledBadge(
                        text: 'Out of Stock',
                        color: Colors.redAccent,
                        fontSize: 10,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      ),
                    ),
                  if (product.isBargainable)
                    Positioned(
                      top: isOutOfStock ? 32 : 8,
                      left: 8,
                      child: _StyledBadge(
                        text: 'Bargain',
                        color: Colors.green.shade700,
                        fontSize: 10,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: widget.onSelectToggle,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: widget.selected ? Colors.green.shade600 : Colors.grey.shade300,
                        child: Icon(
                          widget.selected ? Icons.check : Icons.add,
                          size: 16,
                          color: widget.selected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}