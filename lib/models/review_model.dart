class Review {
  final String? buyerName; // Nullable to support guest reviews
  final int rating;
  final String message;
  final DateTime createdAt;

  Review({
    this.buyerName,
    required this.rating,
    required this.message,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      buyerName: json['buyerName'] as String?,
      rating: json['rating'] ?? 0,
      message: json['message'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Add this getter:
  String get displayBuyerName => (buyerName != null && buyerName!.trim().isNotEmpty) ? buyerName! : 'Anonymous';
}
