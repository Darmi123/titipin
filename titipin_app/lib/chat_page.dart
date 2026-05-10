import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'services/notification_service.dart';
class ChatPage extends StatefulWidget {
  final String orderId;
  final String lawanChatNama;
  const ChatPage({super.key, required this.orderId, required this.lawanChatNama});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _pesanController = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  final _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadChats();
    // Auto refresh setiap 3 detik
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadChats());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pesanController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    final data = await Supabase.instance.client
        .from('chats')
        .select('*, profiles(nama)')
        .eq('order_id', widget.orderId)
        .order('created_at', ascending: true);
    if (mounted) {
      setState(() {
        _chats = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _kirimPesan() async {
    final teks = _pesanController.text.trim();
    if (teks.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    _pesanController.clear();
    await Supabase.instance.client.from('chats').insert({
      'order_id': widget.orderId,
      'pengirim_id': user!.id,
      'pesan': teks,
    });
    final order = await Supabase.instance.client
        .from('orders')
        .select('user_id, driver_id')
        .eq('id', widget.orderId)
        .single();
    final recipientId = order['user_id'] == user!.id
        ? order['driver_id']
        : order['user_id'];
    if (recipientId != null) {
      await NotificationService().notifyNewChat(
        recipientId: recipientId,
        senderName: widget.lawanChatNama,
        message: teks,
        chatRoomId: widget.orderId,
      );
    }
    _loadChats();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B14F),
        title: Text(widget.lawanChatNama,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B14F)))
              : _chats.isEmpty
                ? const Center(
                    child: Text('Belum ada pesan. Mulai chat!',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final isMe = chat['pengirim_id'] == user?.id;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF00B14F) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe && chat['profiles'] != null)
                                Text(chat['profiles']['nama'] ?? '',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00B14F)),
                                ),
                              Text(chat['pesan'],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pesanController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _kirimPesan(),
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _kirimPesan,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00B14F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
