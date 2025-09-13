class GroupBuy {
  final String id;
  final String sellerId;
  final GroupProduct product;
  final String title;
  final String description;
  final double pricePerUnit;
  final int minParticipants;
  final DateTime deadline;
  final List<GroupParticipant> participants;
  final String status;
  final bool visible;
  final int joinedQuantity;
  final bool isFull;

  GroupBuy({
    required this.id,
    required this.sellerId,
    required this.product,
    required this.title,
    required this.description,
    required this.pricePerUnit,
    required this.minParticipants,
    required this.deadline,
    required this.participants,
    required this.status,
    required this.visible,
    required this.joinedQuantity,
    required this.isFull,
  });

  factory GroupBuy.fromJson(Map<String, dynamic> json) {
    final participantList = (json['paidParticipants'] ?? json['participants'] ?? []) as List<dynamic>;

    return GroupBuy(
      id: json['_id']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      product: GroupProduct.fromJson(json['productId'] ?? {}),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pricePerUnit: (json['pricePerUnit'] is num)
          ? (json['pricePerUnit'] as num).toDouble()
          : double.tryParse(json['pricePerUnit'].toString()) ?? 0.0,
      minParticipants: json['minParticipants'] ?? 0,
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? '') ?? DateTime.now(),
      participants: participantList
          .map((p) => GroupParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      status: json['status']?.toString() ?? '',
      visible: json['visible'] ?? true,
      joinedQuantity: json['joinedQuantity'] ?? 0,
      isFull: json['isFull'] ?? false,
    );
  }

  /// Returns the number of people who joined (not quantity)
  int get currentParticipants => participants.length;
}

class GroupProduct {
  final String id;
  final String name;
  final String image;
  final double price;

  GroupProduct({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
  });

  factory GroupProduct.fromJson(Map<String, dynamic> json) {
    final images = List<String>.from(json['images'] ?? []);
    return GroupProduct(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: images.isNotEmpty ? images[0] : '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}

class GroupParticipant {
  final String name;
  final String phone;
  final int quantity;

  GroupParticipant({
    required this.name,
    required this.phone,
    required this.quantity,
  });

  factory GroupParticipant.fromJson(Map<String, dynamic> json) {
    return GroupParticipant(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'quantity': quantity,
    };
  }
}
