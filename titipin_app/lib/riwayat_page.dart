import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';
import 'rating_page.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('warga_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    }
  }

  void _subscribeRealtime() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _channel = Supabase.instance.client
        .channel('orders_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            _loadOrders();
            final newStatus = payload.newRecord['status'];
            if (mounted) {
              String pesan = '';
              Color warna = Colors.green;
              if (newStatus == 'diterima') {
                pesan = '✅ Driver sudah menerima order kamu!';
                warna = Colors.blue;
              } else if (newStatus == 'proses') {
                pesan = '🛵 Driver sedang dalam perjalanan!';
                warna = Colors.orange;
              } else if (newStatus == 'selesai') {
                pesan = '🎉 Order selesai!';
                warna = Colors.green;
              }
              if (pesan.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(pesan), backgroundColor: warna),
                );
              }
            }
          },
        )
        .subscribe();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'menunggu': return Colors.orange;
      case 'diterima': return Colors.blue;
      case 'proses': return const Color(0xFF00B14F);
      case 'selesai': return Colors.green;
      case 'batal': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusEmoji(String status) {
    switch (status) {
      case 'menunggu': return '⏳';
      case 'diterima': return '✅';
      case 'proses': return '🛵';
      case 'selesai': return '🎉';
      case 'batal': return '❌';
      default: return '❓';
    }
  }

  IconData _jenisIcon(String jenis) {
    switch (jenis) {
      case 'jastip': return Icons.shopping_bag_outlined;
      case 'kirim': return Icons.send_outlined;
      case 'jemput': return Icons.directions_bike_outlined;
      case 'kurir': return Icons.delivery_dining_outlined;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B14F),
        title: const Text('Riwayat Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada order', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B14F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_jenisIcon(order['jenis']), color: const Color(0xFF00B14F)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order['jenis'].toString().toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text('Dari: ${order['alamat_asal']}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                Text('Ke: ${order['alamat_tujuan']}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(order['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_statusEmoji(order['status'])} ${order['status']}',
                              style: TextStyle(
                                color: _statusColor(order['status']),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (order['total_biaya'] != null) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total: Rp ${order['total_biaya'].toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B14F)),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (context) => ChatPage(
                                  orderId: order['id'],
                                  lawanChatNama: 'Driver',
                                )),
                              ),
                              icon: const Icon(Icons.chat_outlined, size: 16),
                              label: const Text('Chat Driver'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF00B14F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
