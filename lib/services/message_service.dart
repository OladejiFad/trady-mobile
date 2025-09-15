import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../global/auth_data.dart';

class MessageService {
  // Use localhost for Flutter Web testing, change to LAN IP if testing on another device
  static const baseUrl = 'http://localhost:5000/api/messages';

  // Helper to build headers, optionally with auth token
  static Map<String, String> _buildHeaders(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Fetch messages between two users
  static Future<List<Message>> getMessages(String user1, String user2,
      {String? propertyId, String? token}) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'user1': user1,
        'user2': user2,
        if (propertyId != null && propertyId.isNotEmpty) 'propertyId': propertyId,
      });

      final authToken = token ?? AuthData.token;

      print('GET request URL: $uri'); // Debug print
      final response = await http.get(uri, headers: _buildHeaders(authToken));

      print('Status code: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      print('Network error: $e'); // Debug print
      throw Exception('MessageService.getMessages error: $e');
    }
  }

  // Send a message
  static Future<void> sendMessage(Message message, {String? token}) async {
    final uri = Uri.parse('$baseUrl/send');
    final authToken = token ?? AuthData.token;

    print('POST request URL: $uri'); // Debug
    final response = await http.post(
      uri,
      headers: _buildHeaders(authToken),
      body: jsonEncode(message.toJson()),
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String senderId, String receiverId,
      {String? propertyId, String? token}) async {
    final uri = Uri.parse('$baseUrl/read');
    final authToken = token ?? AuthData.token;

    final response = await http.post(
      uri,
      headers: _buildHeaders(authToken),
      body: jsonEncode({
        'senderId': senderId,
        'receiverId': receiverId,
        if (propertyId != null && propertyId.isNotEmpty) 'propertyId': propertyId,
      }),
    );

    print('Mark read response: ${response.statusCode}, body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to mark messages as read: ${response.body}');
    }
  }

  // Fetch all messages for a given userId
  static Future<List<Message>> getAllMessages({String? userId, String? token}) async {
    final id = userId ??
        (AuthData.role == 'landlord' ? AuthData.landlordId : AuthData.buyerPhone);

    if (id.isEmpty) {
      throw Exception('Missing user ID');
    }

    final uri = Uri.parse('$baseUrl/all').replace(queryParameters: {
      'userId': id,
    });

    final authToken = token ?? AuthData.token;

    print('GET all messages URL: $uri'); // Debug

    final response = await http.get(uri, headers: _buildHeaders(authToken));

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }
}
