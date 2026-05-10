import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  RealtimeChannel? _channel;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChats();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
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

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('chat_realtime_${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chats',
          callback: (payload) async {
            final newChat = payload.newRecord;
            // Fetch nama pengirim
            final profile = await Supabase.instance.client
                .from('profiles')
                .select('nama')
                .eq('id', newChat['pengirim_id'])
                .single();
            newChat['profiles'] = profile;
            if (mounted) {
              setState(() => _chats.add(newChat));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
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
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                            ],
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
