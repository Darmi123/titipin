import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';

class RiwayatChatPage extends StatefulWidget {
  const RiwayatChatPage({super.key});

  @override
  State<RiwayatChatPage> createState() => _RiwayatChatPageState();
}

class _RiwayatChatPageState extends State<RiwayatChatPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Ambil semua order yang punya chat
    final data = await Supabase.instance.client
        .from('orders')
        .select('id, jenis, alamat_asal, alamat_tujuan, status, driver_id, warga_id, created_at')
        .or('warga_id.eq.${user.id},driver_id.eq.${user.id}')
        .not('driver_id', 'is', null)
        .order('created_at', ascending: false);

    setState(() {
      _orders = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  String _getLawanChatNama(Map<String, dynamic> order) {
    final user = Supabase.instance.client.auth.currentUser;
    if (order['warga_id'] == user?.id) return 'Driver';
    return 'Warga';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B14F),
        title: const Text('Pesan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B14F)))
        : _orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💬', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text('Belum ada pesan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Chat dengan driver akan muncul di sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final lawanChat = _getLawanChatNama(order);
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ChatPage(
                      orderId: order['id'],
                      lawanChatNama: lawanChat,
                    )),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B14F).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              lawanChat == 'Driver' ? '🛵' : '🏠',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lawanChat,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text('${order['jenis'].toString().toUpperCase()} • ${order['alamat_asal']}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B14F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF00B14F)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
