import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../models/property_model.dart';
import '../../services/message_service.dart';
import '../../services/property_service.dart';
import '../../services/socket_service.dart';
import '../../global/auth_data.dart';

class LandlordChatScreen extends StatefulWidget {
  final String buyerPhone;
  final String buyerName;
  final String? propertyId;

  const LandlordChatScreen({
    super.key,
    required this.buyerPhone,
    required this.buyerName,
    this.propertyId,
  });

  @override
  State<LandlordChatScreen> createState() => _LandlordChatScreenState();
}

class _LandlordChatScreenState extends State<LandlordChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late SocketService socketService;
  List<Message> _messages = [];
  Property? _property;

  String get currentUserId => AuthData.landlordId;
  String get currentUserName =>
      AuthData.landlordName.isNotEmpty ? AuthData.landlordName : 'Landlord';

  String get chatPartnerId => widget.buyerPhone;
  String get chatPartnerName => widget.buyerName;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    socketService = SocketService();
    socketService.connect(currentUserId);

    socketService.onNewMessage((data) async {
      final newMsg = Message.fromJson(data);
      final isRelevant = (newMsg.senderId == chatPartnerId &&
              newMsg.receiverId == currentUserId) ||
          (newMsg.senderId == currentUserId &&
              newMsg.receiverId == chatPartnerId);
      if (isRelevant) {
        await fetchMessages();
      }
    });

    if (widget.propertyId != null) {
      try {
        final prop =
            await PropertyService.fetchPropertyById(widget.propertyId!);
        setState(() => _property = prop);
      } catch (e) {
        debugPrint('Failed to load property: $e');
      }
    }

    await fetchMessages();
  }

  @override
  void dispose() {
    socketService.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    try {
      final allMessages =
          await MessageService.getAllMessages(userId: currentUserId);

      final filtered = allMessages
          .where((msg) {
            final isBetweenParties =
                (msg.senderId == currentUserId &&
                        msg.receiverId == chatPartnerId) ||
                    (msg.senderId == chatPartnerId &&
                        msg.receiverId == currentUserId);

            final propertyMatches = widget.propertyId == null ||
                msg.propertyId == widget.propertyId;

            return isBetweenParties && propertyMatches;
          })
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      setState(() => _messages = filtered);
      _scrollToBottom();

      await MessageService.markMessagesAsRead(
        chatPartnerId,
        currentUserId,
        propertyId: widget.propertyId,
      );
    } catch (e) {
      debugPrint('Landlord fetch messages error: $e');
    }
  }

  void sendMessage() async {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;

    final msg = Message(
      senderId: currentUserId,
      receiverId: chatPartnerId,
      senderName: currentUserName,
      receiverName: chatPartnerName,
      message: trimmed,
      propertyId: widget.propertyId,
      read: false,
      createdAt: DateTime.now(),
    );

    try {
      await MessageService.sendMessage(msg);
      _controller.clear();
      await fetchMessages();
    } catch (e) {
      debugPrint('Landlord send message error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day &&
        dt.month == now.month &&
        dt.year == now.year) {
      return DateFormat('h:mm a').format(dt);
    }
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  Widget _buildMessage(Message msg) {
    final isMine = msg.senderId == currentUserId;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMine ? Colors.blue[100] : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.message),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatTimestamp(msg.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
                if (isMine) ...[
                  const SizedBox(width: 6),
                  Icon(
                    msg.read ? Icons.done_all : Icons.check,
                    size: 16,
                    color: msg.read ? Colors.blue : Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyHeader() {
    if (_property == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth > 700 ? 600 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Card(
              margin: const EdgeInsets.all(12),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_property!.images.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        _property!.images.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child:
                              const Center(child: Icon(Icons.broken_image, size: 60)),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _property!.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_property!.location} • ₦${_property!.price}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with $chatPartnerName')),
      body: Column(
        children: [
          if (_property != null) _buildPropertyHeader(),
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessage(_messages[index]),
                  ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
