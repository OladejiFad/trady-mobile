class Promo {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final DateTime expiresAt;
  final bool isActive;

  Promo({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.expiresAt,
    required this.isActive,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json['_id'],
      code: json['code'],
      discountType: json['discountType'],
      discountValue: json['discountValue'].toDouble(),
      expiresAt: DateTime.parse(json['expiresAt']),
      isActive: json['isActive'],
    );
  }
}
