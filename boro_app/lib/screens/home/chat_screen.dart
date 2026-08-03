import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int bookingId; // Updated from rideId to bookingId for exact thread matching
  final bool isHost;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.isHost,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  List<dynamic> _messages = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchChat();
    // Auto-refresh chat & price proposals every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchChat());
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel polling when leaving screen
    _msgController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchChat() async {
    final msgs = await ApiService.getChatMessages(widget.bookingId);
    if (mounted) {
      setState(() => _messages = msgs);
    }
  }

  void _sendTextMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    bool success = await ApiService.sendMessage(widget.bookingId, text);
    if (success) {
      _fetchChat();
    }
  }

  void _showProposePriceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Propose Ride Price (₹)',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount (e.g. 150)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final price = double.tryParse(_priceController.text.trim());
                  if (price == null || price <= 0) return;

                  Navigator.pop(ctx);
                  _priceController.clear();
                  bool success = await ApiService.sendPriceProposal(widget.bookingId, price);
                  if (success) {
                    _fetchChat();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                child: const Text('SEND PROPOSAL', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.otherUserName, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // MESSAGES LIST
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet.\nSend a message or propose a price!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];
                      final isMe = item['is_me'] ?? false;
                      final isProposal = item['proposed_price'] != null;

                      if (isProposal) {
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              border: Border.all(color: Colors.amber),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '💰 Price Proposal: ₹${item['proposed_price']}',
                                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                if (!isMe && item['status'] == 'pending') ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          await ApiService.respondToProposal(item['id'], true);
                                          _fetchChat();
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                        child: const Text('Accept'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () async {
                                          await ApiService.respondToProposal(item['id'], false);
                                          _fetchChat();
                                        },
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                                        child: const Text('Reject'),
                                      ),
                                    ],
                                  ),
                                ]
                              ],
                            ),
                          ),
                        );
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.white : const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            item['message'] ?? '',
                            style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 15),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // INPUT BAR
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF1E1E1E),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.monetization_on, color: Colors.amber),
                    tooltip: 'Propose Price',
                    onPressed: _showProposePriceModal,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendTextMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}