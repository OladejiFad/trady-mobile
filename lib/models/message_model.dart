class Message {
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final String message;
  final String? propertyId;
  final bool read;
  final DateTime createdAt;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.message,
    this.propertyId,
    this.read = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        senderId: json['senderId'],
        receiverId: json['receiverId'],
        senderName: json['senderName'],
        receiverName: json['receiverName'],
        message: json['message'],
        propertyId: json['propertyId'],
        read: json['read'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'receiverId': receiverId,
        'senderName': senderName,
        'receiverName': receiverName,
        'message': message,
        'propertyId': propertyId,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };

  // ✅ Add this method to enable `copyWith`
  Message copyWith({
    String? senderId,
    String? receiverId,
    String? senderName,
    String? receiverName,
    String? message,
    String? propertyId,
    bool? read,
    DateTime? createdAt,
  }) {
    return Message(
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      message: message ?? this.message,
      propertyId: propertyId ?? this.propertyId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
