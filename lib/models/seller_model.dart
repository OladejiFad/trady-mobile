class SellerModel {
  final String id;
  final String name;
  final String phone;
  final String location;
  final String status;
  final bool banned;

  final String occupation; // ✅ new
  final String idCard;     // ✅ new
  final String nin;        // ✅ new

  final int productCount;  // ✅ dashboard
  final int orderCount;    // ✅ dashboard
  final num earnings;      // ✅ dashboard

  SellerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.status,
    required this.banned,
    required this.occupation,
    required this.idCard,
    required this.nin,
    required this.productCount,
    required this.orderCount,
    required this.earnings,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? '',
      banned: json['banned'] ?? false,
      occupation: json['occupation'] ?? '',
      idCard: json['idCard'] ?? '',
      nin: json['nin'] ?? '',
      productCount: json['productCount'] ?? 0,
      orderCount: json['orderCount'] ?? 0,
      earnings: json['earnings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'location': location,
      'status': status,
      'banned': banned,
      'occupation': occupation,
      'idCard': idCard,
      'nin': nin,
      'productCount': productCount,
      'orderCount': orderCount,
      'earnings': earnings,
    };
  }
}
