class LandlordModel {
  final String id;
  final String name;
  final String phone;
  final String location;
  final String status; // e.g. 'pending', 'approved', etc.
  final bool banned;
  final String bvn;
  final String? nin;
  final String? internationalPassport;

  LandlordModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.status,
    required this.banned,
    required this.bvn,
    this.nin,
    this.internationalPassport,
  });

  factory LandlordModel.fromJson(Map<String, dynamic> json) {
    return LandlordModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? '',
      banned: json['banned'] ?? false,
      bvn: json['bvn'] ?? '',
      nin: json['nin'],
      internationalPassport: json['internationalPassport'],
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
      'bvn': bvn,
      'nin': nin,
      'internationalPassport': internationalPassport,
    };
  }
}
