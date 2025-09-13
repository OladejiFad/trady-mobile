import 'package:intl/intl.dart';
import '../config.dart';
import '../global/auth_data.dart';

class Location {
  final String address;
  final String? city;
  final String? state;

  Location({
    required this.address,
    this.city,
    this.state,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'] ?? '',
      city: json['city'],
      state: json['state'],
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'city': city,
        'state': state,
      };
}

class Availability {
  final bool isAvailable;
  final DateTime? availableFrom;
  final int? leaseDurationMonths;

  Availability({
    required this.isAvailable,
    this.availableFrom,
    this.leaseDurationMonths,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      isAvailable: json['isAvailable'] ?? true,
      availableFrom: json['availableFrom'] != null
          ? DateTime.tryParse(json['availableFrom'])
          : null,
      leaseDurationMonths: json['leaseDurationMonths'],
    );
  }

  Map<String, dynamic> toJson() => {
        'isAvailable': isAvailable,
        'availableFrom': availableFrom?.toIso8601String(),
        'leaseDurationMonths': leaseDurationMonths,
      };
}

class Property {
  final String id;
  final String title;
  final String description;
  final double price;
  final Location location;
  final String landlordId;
  final String? landlordName;
  final List<String> images;
  final String? mainImage;
  final String type;
  final String transactionType;
  final bool verified;
  final String status;
  final DateTime? createdAt;
  final List<String> amenities;
  final Availability? availability;
  final int? bedrooms;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.landlordId,
    this.landlordName,
    required this.images,
    this.mainImage,
    required this.type,
    required this.transactionType,
    required this.verified,
    required this.status,
    this.createdAt,
    required this.amenities,
    this.availability,
    this.bedrooms,
  });

  /// ✅ Full image URL
  String? get imageUrl {
    if (mainImage == null || mainImage!.isEmpty) return null;
    return '$baseUrl/uploads/$mainImage';
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['_id']?.toString() ?? '', // ✅ Ensure proper ID assignment
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : Location(address: ''),
      landlordId: json['landlordId']?.toString() ?? json['owner']?.toString() ?? '',
      landlordName: json['landlordName'] ?? json['landlord']?['name'],
      images: List<String>.from(json['images'] ?? []),
      mainImage: json['mainImage'],
      type: json['propertyType'] ?? json['type'] ?? '',
      transactionType: json['transactionType'] ?? '',
      verified: json['verified'] ?? false,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      amenities: List<String>.from(json['amenities'] ?? []),
      availability: json['availability'] != null
          ? Availability.fromJson(json['availability'])
          : null,
      bedrooms: json['bedrooms'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'description': description,
        'price': price,
        'location': location.toJson(),
        'landlordId': landlordId,
        'landlordName': landlordName,
        'images': images,
        'mainImage': mainImage,
        'propertyType': type,
        'transactionType': transactionType,
        'verified': verified,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
        'amenities': amenities,
        'availability': availability?.toJson(),
        'bedrooms': bedrooms,
      };
}
