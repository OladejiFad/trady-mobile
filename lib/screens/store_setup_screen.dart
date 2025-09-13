import 'package:flutter/material.dart';
import '../models/store_model.dart';
import '../services/store_service.dart';

const Color coral = Color(0xFFFF7F50);

class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({Key? key}) : super(key: key);

  @override
  _StoreSetupScreenState createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String storeName = '';
  String storeTheme = '';
  String storeDescription = '';
  String storeCategory = '';
  String storeOccupation = '';
  String occupationType = '';

  bool isLoading = false;
  Store? existingStore;

  final storeService = StoreService();

  final List<String> themes = [
    'Scandinavian Minimal',
    'Tokyo Night',
    'Urban Chic',
    'Bohemian Vibrant',
    'Coastal Serenity',
    'Rustic Charm',
    'Modern Loft',
    'Vintage Retro',
    'Tropical Oasis',
    'Industrial Edge',
    'Midnight Blue',
    'Desert Sunset',
    'Forest Whisper',
    'Urban Jungle',
    'Classic Elegance',
    'Nordic Frost',
    'Sunlit Meadow',
    'Cosmic Dream',
    'Art Deco Glam',
    'Minimal Zen',
  ];

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    setState(() => isLoading = true);
    Store? store = await storeService.fetchMyStore();

    if (store != null) {
      setState(() {
        existingStore = store;

        // Initialize form fields from existing store
        storeName = store.storeName;
        storeTheme = store.storeTheme;
        storeDescription = store.storeDescription;
        storeCategory = store.storeCategory ?? '';
        storeOccupation = store.storeOccupation;
        occupationType = store.occupationType;
      });

      if (storeTheme.isNotEmpty && !themes.contains(storeTheme)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Your previous theme is no longer supported. Please choose a new one.",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade600,
              duration: Duration(seconds: 4),
            ),
          );
        });
      }
    }
    setState(() => isLoading = false);
  }

  /// Helper: derive occupationType from storeOccupation (or empty if unknown)
  String _deriveOccupationType(String occupation) {
    switch (occupation.toLowerCase()) {
      case 'vendor':
        return 'Vendor';
      case 'skillworker':
      case 'skill worker':
        return 'Skill Workers';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    // If occupationTypeLocked, keep existing occupationType; else derive from storeOccupation
    final resolvedOccupationType = (existingStore?.occupationTypeLocked ?? false)
        ? existingStore!.occupationType
        : _deriveOccupationType(storeOccupation);

    // Construct the updated Store object
    final updatedStore = Store(
      id: existingStore?.id ?? '',
      sellerId: existingStore?.sellerId ?? '',
      // If storeName is locked, keep existing storeName
      storeName: (existingStore?.storeNameLocked ?? false)
          ? existingStore!.storeName
          : storeName,
      storeTheme: storeTheme,
      storeDescription: storeDescription,
      storeCategory: storeCategory,
      storeNameLocked: existingStore?.storeNameLocked ?? false,
      occupationTypeLocked: existingStore?.occupationTypeLocked ?? false,
      // If occupation is locked or already set, keep existing storeOccupation; else use form value
      storeOccupation: (existingStore?.occupationTypeLocked ?? false ||
              (existingStore?.storeOccupation.isNotEmpty ?? false))
          ? existingStore!.storeOccupation
          : storeOccupation,
      occupationType: (existingStore?.occupationTypeLocked ?? false)
          ? existingStore!.occupationType
          : resolvedOccupationType,
      storeScore: existingStore?.storeScore,
      isTopSeller: existingStore?.isTopSeller ?? false,
    );

    setState(() => isLoading = true);
    bool success = await storeService.setupOrUpdateStore(updatedStore);
    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Store setup/updated successfully' : 'Failed to setup/update store',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: success ? Colors.teal.shade600 : Colors.red.shade600,
      ),
    );

    if (success) {
      // Optionally reload store data to refresh UI
      _loadStore();
    }
  }

  // Colors helpers for theme preview
  Color _getTextColor(String theme) {
    switch (theme) {
      case 'Tokyo Night':
      case 'Coastal Serenity':
      case 'Midnight Blue':
      case 'Nordic Frost':
      case 'Cosmic Dream':
        return Colors.white;
      default:
        return Colors.black87;
    }
  }

  Color _getStarColor(String theme) {
    switch (theme) {
      case 'Scandinavian Minimal':
        return Color(0xFFF4A261).withOpacity(0.6); // Faded peach
      case 'Tokyo Night':
        return Color(0xFF00D4FF).withOpacity(0.7); // Faded cyan
      case 'Urban Chic':
        return Color(0xFF6B7280).withOpacity(0.7); // Faded gray
      case 'Bohemian Vibrant':
        return Color(0xFF2A9D8F).withOpacity(0.8); // Faded teal
      case 'Coastal Serenity':
        return Color(0xFFFFD166).withOpacity(0.6); // Faded yellow
      case 'Rustic Charm':
        return Color(0xFF8B4513).withOpacity(0.7); // Faded saddle brown
      case 'Modern Loft':
        return Color(0xFF4B5EAA).withOpacity(0.6); // Faded slate blue
      case 'Vintage Retro':
        return Color(0xFFDAA520).withOpacity(0.7); // Faded goldenrod
      case 'Tropical Oasis':
        return Color(0xFF2ECC71).withOpacity(0.8); // Faded emerald
      case 'Industrial Edge':
        return Color(0xFF708090).withOpacity(0.6); // Faded slate gray
      case 'Midnight Blue':
        return Color(0xFF191970).withOpacity(0.7); // Faded navy
      case 'Desert Sunset':
        return Color(0xFFF28C38).withOpacity(0.6); // Faded orange
      case 'Forest Whisper':
        return Color(0xFF228B22).withOpacity(0.7); // Faded forest green
      case 'Urban Jungle':
        return Color(0xFF9ACD32).withOpacity(0.8); // Faded lime green
      case 'Classic Elegance':
        return Color(0xFF800000).withOpacity(0.6); // Faded maroon
      case 'Nordic Frost':
        return Color(0xFFB0C4DE).withOpacity(0.7); // Faded light steel blue
      case 'Sunlit Meadow':
        return Color(0xFFFFE4B5).withOpacity(0.6); // Faded moccasin
      case 'Cosmic Dream':
        return Color(0xFF9932CC).withOpacity(0.7); // Faded dark orchid
      case 'Art Deco Glam':
        return Color(0xFFD4A017).withOpacity(0.8); // Faded gold
      case 'Minimal Zen':
        return Color(0xFF4682B4).withOpacity(0.6); // Faded steel blue
      default:
        return Colors.brown.shade700.withOpacity(0.7); // Faded default brown
    }
  }

  Widget _buildThemePreview() {
    final Map<String, IconData> themeIcons = {
      'Scandinavian Minimal': Icons.light,
      'Tokyo Night': Icons.nightlight_round,
      'Urban Chic': Icons.apartment,
      'Bohemian Vibrant': Icons.color_lens,
      'Coastal Serenity': Icons.beach_access,
      'Rustic Charm': Icons.forest,
      'Modern Loft': Icons.meeting_room,
      'Vintage Retro': Icons.radio,
      'Tropical Oasis': Icons.local_florist,
      'Industrial Edge': Icons.build,
      'Midnight Blue': Icons.nightlight,
      'Desert Sunset': Icons.wb_sunny,
      'Forest Whisper': Icons.park,
      'Urban Jungle': Icons.eco,
      'Classic Elegance': Icons.account_balance,
      'Nordic Frost': Icons.ac_unit,
      'Sunlit Meadow': Icons.wb_sunny,
      'Cosmic Dream': Icons.stars, // Replaced starfield with stars
      'Art Deco Glam': Icons.theaters,
      'Minimal Zen': Icons.spa,
    };

    final Map<String, String> themeImages = {
      'Scandinavian Minimal': 'https://images.pexels.com/photos/1350789/pexels-photo-1350789.jpeg',
      'Tokyo Night': 'https://images.pexels.com/photos/291762/pexels-photo-291762.jpeg',
      'Urban Chic': 'https://images.pexels.com/photos/1080696/pexels-photo-1080696.jpeg',
      'Bohemian Vibrant': 'https://images.pexels.com/photos/1054974/pexels-photo-1054974.jpeg',
      'Coastal Serenity': 'https://images.pexels.com/photos/775219/pexels-photo-775219.jpeg',
      'Rustic Charm': 'https://images.pexels.com/photos/1084188/pexels-photo-1084188.jpeg',
      'Modern Loft': 'https://images.pexels.com/photos/2635038/pexels-photo-2635038.jpeg',
      'Vintage Retro': 'https://images.pexels.com/photos/1632790/pexels-photo-1632790.jpeg',
      'Tropical Oasis': 'https://images.pexels.com/photos/1693946/pexels-photo-1693946.jpeg',
      'Industrial Edge': 'https://images.pexels.com/photos/209251/pexels-photo-209251.jpeg',
      'Midnight Blue': 'https://images.pexels.com/photos/1629236/pexels-photo-1629236.jpeg',
      'Desert Sunset': 'https://images.pexels.com/photos/360912/pexels-photo-360912.jpeg',
      'Forest Whisper': 'https://images.pexels.com/photos/15286/pexels-photo.jpg',
      'Urban Jungle': 'https://images.pexels.com/photos/2901581/pexels-photo-2901581.jpeg',
      'Classic Elegance': 'https://images.pexels.com/photos/813692/pexels-photo-813692.jpeg',
      'Nordic Frost': 'https://images.pexels.com/photos/164338/pexels-photo-164338.jpeg',
      'Sunlit Meadow': 'https://images.pexels.com/photos/1586298/pexels-photo-1586298.jpeg',
      'Cosmic Dream': 'https://images.pexels.com/photos/355465/pexels-photo-355465.jpeg',
      'Art Deco Glam': 'https://images.pexels.com/photos/2100487/pexels-photo-2100487.jpeg',
      'Minimal Zen': 'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg',
    };

    return FadeInAnimation(
      duration: const Duration(milliseconds: 500),
      child: Container(
        height: 150,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade100, Colors.teal.shade50],
          ),
          image: themeImages.containsKey(storeTheme)
              ? DecorationImage(
                  image: NetworkImage(themeImages[storeTheme]!),
                  fit: BoxFit.cover,
                )
              : null,
          border: Border.all(color: Colors.teal.shade200, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                'Live Preview: $storeTheme',
                style: TextStyle(
                  fontSize: 22,
                  color: _getTextColor(storeTheme),
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
            if (themeIcons.containsKey(storeTheme))
              Positioned(
                top: 8,
                left: 8,
                child: Icon(
                  themeIcons[storeTheme],
                  size: 36,
                  color: _getTextColor(storeTheme),
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.star,
                color: _getStarColor(storeTheme),
                size: 36,
                shadows: [
                  Shadow(
                    color: _getStarColor(storeTheme).withOpacity(0.9),
                    blurRadius: 12,
                    offset: const Offset(1, 3),
                  ),
                  Shadow(
                    color: _getStarColor(storeTheme).withOpacity(0.6),
                    blurRadius: 20,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && existingStore == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Store Setup',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.teal.shade700, Colors.teal.shade500],
              ),
            ),
          ),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        body: Center(child: CircularProgressIndicator(color: Colors.teal.shade600)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          existingStore != null ? 'Update Store' : 'Store Setup',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal.shade700, Colors.teal.shade500],
            ),
          ),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        existingStore != null ? 'Update Your Store' : 'Set Up Your Store',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),

                      // Store Name field: disabled if locked or exists
                      if (existingStore != null && existingStore!.storeNameLocked)
                        TextFormField(
                          initialValue: existingStore!.storeName,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Store Name',
                            labelStyle: TextStyle(color: Colors.teal.shade800),
                            helperText: 'Store name can’t be changed',
                            filled: true,
                            fillColor: Colors.teal.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.store, color: Colors.teal.shade600),
                          ),
                          style: TextStyle(color: Colors.grey.shade700),
                        )
                      else if (existingStore != null)
                        TextFormField(
                          initialValue: existingStore!.storeName,
                          enabled: true,
                          decoration: InputDecoration(
                            labelText: 'Store Name',
                            labelStyle: TextStyle(color: Colors.teal.shade800),
                            filled: true,
                            fillColor: Colors.teal.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.store, color: Colors.teal.shade600),
                          ),
                          onSaved: (val) => storeName = val ?? '',
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          style: TextStyle(color: Colors.grey.shade800),
                        )
                      else
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Store Name',
                            labelStyle: TextStyle(color: Colors.teal.shade800),
                            filled: true,
                            fillColor: Colors.teal.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.store, color: Colors.teal.shade600),
                          ),
                          onSaved: (val) => storeName = val ?? '',
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),

                      const SizedBox(height: 24),

                      // Store Theme dropdown
                      DropdownButtonFormField<String>(
                        value: themes.contains(storeTheme) ? storeTheme : null,
                        items: themes.map((theme) {
                          return DropdownMenuItem<String>(
                            value: theme,
                            child: Text(
                              theme,
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Store Theme',
                          labelStyle: TextStyle(color: Colors.teal.shade800),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.palette, color: Colors.teal.shade600),
                        ),
                        onChanged: (value) {
                          setState(() => storeTheme = value ?? '');
                        },
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),

                      _buildThemePreview(),

                      const SizedBox(height: 16),

                      // Store Description
                      TextFormField(
                        initialValue: storeDescription,
                        decoration: InputDecoration(
                          labelText: 'Store Description',
                          labelStyle: TextStyle(color: Colors.teal.shade800),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.description, color: Colors.teal.shade600),
                        ),
                        onSaved: (val) => storeDescription = val ?? '',
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        maxLines: 3,
                        style: TextStyle(color: Colors.grey.shade800),
                      ),

                      const SizedBox(height: 16),

                      // Store Occupation dropdown
                      DropdownButtonFormField<String>(
                        value: storeOccupation.isNotEmpty ? storeOccupation : null,
                        items: ['vendor', 'skillworker'].map((occupation) {
                          return DropdownMenuItem<String>(
                            value: occupation,
                            child: Text(
                              occupation == 'vendor'
                                  ? 'Vendor (Product Seller)'
                                  : 'Skill Worker (Service Provider)',
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Store Occupation',
                          helperText: existingStore?.storeOccupation?.isNotEmpty == true
                              ? 'This can’t be changed after setup'
                              : null,
                          labelStyle: TextStyle(color: Colors.teal.shade800),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.work, color: Colors.teal.shade600),
                        ),
                        onChanged: existingStore?.storeOccupation?.isNotEmpty == true
                            ? null
                            : (value) {
                                setState(() => storeOccupation = value ?? '');
                              },
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 16),

                      // Occupation Type (read-only)
                      TextFormField(
                        initialValue: occupationType,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Occupation Type',
                          helperText: 'System assigned - cannot be changed',
                          labelStyle: TextStyle(color: Colors.teal.shade800),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.info, color: Colors.teal.shade600),
                        ),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),

                      const SizedBox(height: 16),

                      // Store Category (optional)
                      TextFormField(
                        initialValue: storeCategory,
                        decoration: InputDecoration(
                          labelText: 'Store Category',
                          helperText:
                              'E.g. Handwork, Fashion, Hair Vendor, Electronics, Other (Optional)',
                          labelStyle: TextStyle(color: Colors.teal.shade800),
                          filled: true,
                          fillColor: Colors.teal.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.category, color: Colors.teal.shade600),
                        ),
                        onSaved: (val) => storeCategory = val ?? '',
                        validator: (val) => null, // Optional
                        style: TextStyle(color: Colors.grey.shade800),
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade700, Colors.amber.shade500],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          child: Text(
                            'Save Store',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
        ),
      ),
    );
  }
}

// Your FadeInAnimation widget as-is

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
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
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeInAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.reset();
    _controller.forward();
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