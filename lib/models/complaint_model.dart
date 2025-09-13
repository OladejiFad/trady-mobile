class Complaint {
  final String id;
  final String subject;
  final String description;
  final String response;
  final String status;
  final String userId; // buyerPhone or sellerId
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime? createdAt; // ✅ Add this

  Complaint({
    required this.id,
    required this.subject,
    required this.description,
    required this.response,
    required this.status,
    required this.userId,
    this.resolvedBy,
    this.resolvedAt,
    this.createdAt, // ✅ Add to constructor
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['_id'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      response: json['response'] ?? '',
      status: json['status'] ?? 'pending',
      userId: json['userId'] ?? '',
      resolvedBy: json['resolvedBy'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null, // ✅ Parse createdAt
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'subject': subject,
      'description': description,
      'response': response,
      'status': status,
      'userId': userId,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(), // ✅ Add to JSON
    };
  }
}
