import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../global/auth_data.dart';
import '../../models/message_model.dart';
import '../../models/property_model.dart';
import '../../services/message_service.dart';
import '../../services/socket_service.dart';
import '../../services/property_service.dart'; // <-- Add this import

class BuyerChatScreen extends StatefulWidget {
  final String landlordId;
  final String landlordName;
  final String propertyId;

  const BuyerChatScreen({
    super.key,
    required this.landlordId,
    required this.landlordName,
    required this.propertyId,
  });

  @override
  State<BuyerChatScreen> createState() => _BuyerChatScreenState();
}

class _BuyerChatScreenState extends State<BuyerChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late SocketService socketService;

  Property? _property;
  bool _isSending = false;
  bool _isLoading = true;

  String get buyerId => AuthData.buyerPhone;
  String get buyerName => AuthData.buyerName;

  String get displayLandlordName =>
      (widget.landlordName.trim().isNotEmpty)
          ? widget.landlordName.trim()
          : 'Landlord';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    socketService = SocketService();
    socketService.connect(buyerId);

    socketService.onNewMessage((data) {
      final newMsg = Message.fromJson(data);
      final isRelevant =
          newMsg.propertyId == widget.propertyId &&
          ((newMsg.senderId == widget.landlordId &&
                  newMsg.receiverId == buyerId) ||
              (newMsg.senderId == buyerId &&
                  newMsg.receiverId == widget.landlordId));
      if (isRelevant) {
        _loadMessages();
      }
    });

    await Future.wait([
      _loadMessages(),
      _loadProperty(),
    ]);
  }

  Future<void> _loadProperty() async {
    try {
      final prop =
          await PropertyService.fetchPropertyById(widget.propertyId);
      setState(() => _property = prop);
    } catch (e) {
      debugPrint('Failed to load property: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final allMessages = await MessageService.getAllMessages(userId: buyerId);
      final relevantMessages = allMessages
          .where((msg) =>
              msg.propertyId == widget.propertyId &&
              ((msg.senderId == buyerId &&
                      msg.receiverId == widget.landlordId) ||
                  (msg.senderId == widget.landlordId &&
                      msg.receiverId == buyerId)))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      setState(() {
        _messages.clear();
        _messages.addAll(relevantMessages);
        _isLoading = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();

      await MessageService.markMessagesAsRead(
        widget.landlordId,
        buyerId,
        propertyId: widget.propertyId,
      );
    } catch (e) {
      debugPrint('Failed to load messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final newMessage = Message(
      senderId: buyerId,
      receiverId: widget.landlordId,
      senderName: buyerName.isNotEmpty ? buyerName : 'Buyer',
      receiverName: displayLandlordName,
      message: text,
      propertyId: widget.propertyId,
      read: false,
      createdAt: DateTime.now(),
    );

    try {
      await MessageService.sendMessage(newMessage);

      setState(() {
        _messages.add(newMessage);
        _controller.clear();
        _isSending = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
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

  Widget _buildMessage(Message msg) {
    final isBuyer = msg.senderId == buyerId;
    return Align(
      alignment: isBuyer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isBuyer ? Colors.deepPurple.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isBuyer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(msg.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (isBuyer) ...[
                  const SizedBox(width: 4),
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

  Widget _buildPropertyCard() {
    if (_property == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Row(
        children: [
          if (_property!.imageUrl != null && _property!.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8)),
              child: Image.network(
                _property!.imageUrl!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: ListTile(
              title: Text(_property!.title ?? 'Property'),
              subtitle: Text(_property!.location?.toString() ?? ''),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socketService.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $displayLandlordName'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          _buildPropertyCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) =>
                            _buildMessage(_messages[index]),
                      ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
