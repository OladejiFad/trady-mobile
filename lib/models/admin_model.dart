class Admin {
  final String id;
  final String username;
  final String token;

  Admin({
    required this.id,
    required this.username,
    required this.token,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'],
      username: json['username'],
      token: json['token'],
    );
  }
}
