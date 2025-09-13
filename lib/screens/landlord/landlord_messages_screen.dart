import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../global/auth_data.dart';
import '../../models/message_model.dart';
import '../../models/property_model.dart';
import '../../services/message_service.dart';
import '../../services/property_service.dart';
import '../landlord/landlord_chat_screen.dart';

class LandlordMessagesScreen extends StatefulWidget {
  const LandlordMessagesScreen({super.key});

  @override
  State<LandlordMessagesScreen> createState() => _LandlordMessagesScreenState();
}

class _LandlordMessagesScreenState extends State<LandlordMessagesScreen> {
  List<Message> _allMessages = [];
  Map<String, Property> _propertyCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final messages = await MessageService.getAllMessages(userId: AuthData.landlordId);
      setState(() {
        _allMessages = messages;
        _isLoading = false;
      });
      await _fetchRelatedProperties(messages);
    } catch (e) {
      debugPrint('Failed to fetch messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRelatedProperties(List<Message> messages) async {
    final ids = messages
        .map((m) => m.propertyId)
        .where((id) => id != null && !_propertyCache.containsKey(id))
        .cast<String>()
        .toSet();

    for (final id in ids) {
      try {
        final property = await PropertyService.fetchPropertyById(id);
        if (property != null) {
          _propertyCache[id] = property;
        }
      } catch (e) {
        debugPrint('Failed to fetch property $id: $e');
      }
    }

    setState(() {});
  }

  Map<String, Message> get _latestByBuyerPerProperty {
    final Map<String, Message> map = {};
    for (final msg in _allMessages) {
      if (msg.senderId == AuthData.landlordId || msg.receiverId == AuthData.landlordId) {
        final buyerId = msg.senderId == AuthData.landlordId ? msg.receiverId : msg.senderId;
        final propertyId = msg.propertyId ?? 'noProperty';
        final key = '$buyerId|$propertyId';

        if (!map.containsKey(key) || msg.createdAt.isAfter(map[key]!.createdAt)) {
          map[key] = msg;
        }
      }
    }
    return map;
  }

  int _countUnreadFrom(String buyerId, String? propertyId) {
    return _allMessages.where((msg) =>
      msg.senderId == buyerId &&
      msg.receiverId == AuthData.landlordId &&
      msg.propertyId == propertyId &&
      !msg.read
    ).length;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat.yMd().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages from Buyers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMessages,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMessages,
              child: ListView(
                children: _latestByBuyerPerProperty.entries.map((entry) {
                  final msg = entry.value;
                  final parts = entry.key.split('|');
                  final buyerId = parts[0];
                  final propertyId = parts.length > 1 ? parts[1] : null;
                  final unreadCount = _countUnreadFrom(buyerId, propertyId);

                  final property = propertyId != null ? _propertyCache[propertyId] : null;

                  return ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LandlordChatScreen(
                          buyerPhone: msg.senderId == AuthData.landlordId
                              ? msg.receiverId
                              : msg.senderId,
                          buyerName: msg.senderId == AuthData.landlordId
                              ? msg.receiverName
                              : msg.senderName,
                          propertyId: propertyId,
                        ),
                      ),
                    ),
                    leading: property != null && property.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              property.imageUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.home),
                            ),
                          )
                        : const Icon(Icons.home, size: 40),
                    title: Text(
                      msg.senderId == AuthData.landlordId
                          ? msg.receiverName
                          : msg.senderName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (property != null)
                          Text(
                            property.title,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        Text(
                          msg.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(msg.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
