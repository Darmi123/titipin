import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final data = await Supabase.instance.client
        .from('orders')
        .select()
        .eq('status', 'menunggu')
        .order('created_at', ascending: false);
    setState(() {
      _orders = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _terimaOrder(String orderId) async {
    final user = Supabase.instance.client.auth.currentUser;
    await Supabase.instance.client.from('orders').update({
      'driver_id': user!.id,
      'status': 'diterima',
    }).eq('id', orderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order berhasil diterima!'),
          backgroundColor: Color(0xFF00B14F),
        ),
      );
      _loadOrders();
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
        title: const Text('Order Tersedia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  Text('Tidak ada order saat ini', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B14F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_jenisIcon(order['jenis']), color: const Color(0xFF00B14F)),
                          ),
                          const SizedBox(width: 12),
                          Text(order['jenis'].toString().toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(order['metode_bayar'].toString().toUpperCase(),
                              style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Color(0xFF00B14F), size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(order['alamat_asal'], style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(order['alamat_tujuan'], style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _terimaOrder(order['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B14F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Terima Order', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
