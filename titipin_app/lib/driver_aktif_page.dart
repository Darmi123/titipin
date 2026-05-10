import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';

class DriverAktifPage extends StatefulWidget {
  const DriverAktifPage({super.key});

  @override
  State<DriverAktifPage> createState() => _DriverAktifPageState();
}

class _DriverAktifPageState extends State<DriverAktifPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    final data = await Supabase.instance.client
        .from('orders')
        .select()
        .eq('driver_id', user!.id)
        .inFilter('status', ['diterima', 'proses'])
        .order('created_at', ascending: false);
    setState(() {
      _orders = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(String orderId, String status) async {
    await Supabase.instance.client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
    _loadOrders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'proses' ? '🛵 Status diubah ke Proses!' : '🎉 Order selesai!'),
          backgroundColor: const Color(0xFF00B14F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B14F),
        title: const Text('Pesanan Aktif', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadOrders();
            },
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B14F)))
        : _orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tidak ada pesanan aktif', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: order['status'] == 'diterima'
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order['status'] == 'diterima' ? '✅ Diterima' : '🛵 Proses',
                              style: TextStyle(
                                color: order['status'] == 'diterima' ? Colors.blue : Colors.orange,
                                fontSize: 12, fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(order['jenis'].toString().toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.store_outlined, color: Color(0xFF00B14F), size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(order['alamat_asal'] ?? '-', style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(order['alamat_tujuan'] ?? '-', style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                      if (order['catatan'] != null && order['catatan'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.note_outlined, color: Colors.grey, size: 16),
                            const SizedBox(width: 4),
                            Expanded(child: Text(order['catatan'], style: const TextStyle(fontSize: 13, color: Colors.grey))),
                          ],
                        ),
                      ],
                      if (order['total_biaya'] != null) ...[
                        const SizedBox(height: 8),
                        Text('Total: Rp ${order['total_biaya'].toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B14F)),
                        ),
                        Text('Bayar: ${order['metode_bayar'].toString().toUpperCase()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (context) => ChatPage(
                                  orderId: order['id'],
                                  lawanChatNama: 'Warga',
                                )),
                              ),
                              icon: const Icon(Icons.chat_outlined, size: 16),
                              label: const Text('Chat Warga'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00B14F),
                                side: const BorderSide(color: Color(0xFF00B14F)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus(
                                order['id'],
                                order['status'] == 'diterima' ? 'proses' : 'selesai',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00B14F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                order['status'] == 'diterima' ? 'Mulai Proses' : 'Selesai',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
