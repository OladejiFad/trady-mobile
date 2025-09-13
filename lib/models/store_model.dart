class Store {
  final String id;
  final String sellerId;
  final String storeName;
  final String storeTheme;
  final String storeDescription;
  final String? storeCategory;       // Optional field
  final bool storeNameLocked;
  final String storeOccupation;      // Free-text user input
  final String occupationType;       // 'Skill Workers' or 'Vendor'
  final bool occupationTypeLocked;   // 🔒 New field
  final double? storeScore;          // Optional store score
  final bool isTopSeller;            // Flag to mark top sellers

  Store({
    required this.id,
    required this.sellerId,
    required this.storeName,
    required this.storeTheme,
    required this.storeDescription,
    this.storeCategory,
    required this.storeNameLocked,
    required this.storeOccupation,
    required this.occupationType,
    required this.occupationTypeLocked, // ✅ required
    this.storeScore,
    this.isTopSeller = false,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['_id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      storeName: json['storeName'] ?? '',
      storeTheme: json['storeTheme'] ?? '',
      storeDescription: json['storeDescription'] ?? '',
      storeCategory: json['storeCategory'],
      storeNameLocked: json['storeNameLocked'] ?? false,
      storeOccupation: json['storeOccupation'] ?? '',
      occupationType: json['occupationType'] ?? '',
      occupationTypeLocked: json['occupationTypeLocked'] ?? false, // ✅ parse from JSON
      storeScore: (json['storeScore'] as num?)?.toDouble(),
      isTopSeller: json['isTopSeller'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'storeName': storeName,
      'storeTheme': storeTheme,
      'storeDescription': storeDescription,
      'storeNameLocked': storeNameLocked,
      'storeOccupation': storeOccupation,
      'occupationType': occupationType,
      'occupationTypeLocked': occupationTypeLocked, // ✅ send to backend
      'isTopSeller': isTopSeller,
    };

    if (storeCategory != null && storeCategory!.isNotEmpty) {
      data['storeCategory'] = storeCategory;
    }
    if (storeScore != null) {
      data['storeScore'] = storeScore;
    }

    return data;
  }

  Store copyWith({
    String? id,
    String? sellerId,
    String? storeName,
    String? storeTheme,
    String? storeDescription,
    String? storeCategory,
    bool? storeNameLocked,
    String? storeOccupation,
    String? occupationType,
    bool? occupationTypeLocked,
    double? storeScore,
    bool? isTopSeller,
  }) {
    return Store(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      storeName: storeName ?? this.storeName,
      storeTheme: storeTheme ?? this.storeTheme,
      storeDescription: storeDescription ?? this.storeDescription,
      storeCategory: storeCategory ?? this.storeCategory,
      storeNameLocked: storeNameLocked ?? this.storeNameLocked,
      storeOccupation: storeOccupation ?? this.storeOccupation,
      occupationType: occupationType ?? this.occupationType,
      occupationTypeLocked: occupationTypeLocked ?? this.occupationTypeLocked,
      storeScore: storeScore ?? this.storeScore,
      isTopSeller: isTopSeller ?? this.isTopSeller,
    );
  }
}
