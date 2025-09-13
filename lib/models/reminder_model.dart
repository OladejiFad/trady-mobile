class Reminder {
  final String id;
  final String message;
  final String createdBy; // optional if not in your DB yet
  final DateTime remindAt;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.message,
    required this.createdBy,
    required this.remindAt,
    required this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['_id'],
      message: json['message'],
      createdBy: json['createdBy'] ?? '', // default or handle if null
      remindAt: DateTime.parse(json['remindAt']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'remindAt': remindAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}
