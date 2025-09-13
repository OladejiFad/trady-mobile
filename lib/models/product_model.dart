import 'review_model.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final List<String> imageUrls;
  final String sellerId;
  final String? marketSection;
  final List<String> sizes;
  final List<String> colors;
  final List<Review> reviews;
  final Review? latestReview;
  final int discount; // ✅ Existing field
  final bool isBargainable; // ✅ NEW FIELD

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.imageUrls,
    required this.sellerId,
    this.marketSection,
    this.sizes = const [],
    this.colors = const [],
    this.reviews = const [],
    this.latestReview,
    this.discount = 0,
    this.isBargainable = false, // ✅ NEW FIELD
  });

  /// ✅ Aliased getter for legacy compatibility
  int get stockQuantity => stock;

  /// ✅ Calculates the discounted price (if any)
  double get discountedPrice {
    if (discount > 0 && discount <= 100) {
      return price * (1 - discount / 100);
    }
    return price;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    Review? parsedLatestReview;
    try {
      if (json['review'] != null && json['review'] is Map<String, dynamic>) {
        parsedLatestReview = Review.fromJson(json['review']);
        print('✅ Parsed latestReview for product "${json['name']}"');
      } else {
        print('ℹ️ No latestReview found for product "${json['name']}"');
      }
    } catch (e, st) {
      print('❌ Failed to parse latestReview for product "${json['name']}": $e');
      print(st);
    }

    final reviewsList = <Review>[];
    try {
      if (json['reviews'] != null && json['reviews'] is List) {
        reviewsList.addAll((json['reviews'] as List)
            .map((r) => Review.fromJson(r))
            .toList());
        print('📦 Loaded ${reviewsList.length} reviews for "${json['name']}"');
      }
    } catch (e, st) {
      print('❌ Failed to parse reviews list for "${json['name']}": $e');
      print(st);
    }

    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? json['stockQuantity'] ?? 0,
      imageUrls: List<String>.from(json['images'] ?? []),
      sellerId: json['sellerId'] ?? json['seller']?['_id'] ?? '',
      marketSection: json['marketSection'],
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      reviews: reviewsList,
      latestReview: parsedLatestReview,
      discount: json['discount'] ?? 0,
      isBargainable: json['isBargainable'] ?? false, // ✅ NEW FIELD
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'stock': stock,
      'sellerId': sellerId,
      if (marketSection != null) 'marketSection': marketSection,
      'sizes': sizes,
      'colors': colors,
      'discount': discount,
      'isBargainable': isBargainable, // ✅ NEW FIELD
    };
  }
}
