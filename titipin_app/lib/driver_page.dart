import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'chat_page.dart';
import 'driver_aktif_page.dart';
import 'jarak_service.dart';
import 'services/notification_service.dart';

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;
  Position? _posisiDriver;
  bool _isLoadingLokasi = false;

  @override
  void initState() {
    super.initState();
    _ambilLokasidanMuatOrder();
    _subscribeRealtime();
    NotificationService().fetchNotifications();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _ambilLokasidanMuatOrder() async {
    setState(() => _isLoadingLokasi = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aktifkan GPS di pengaturan!'), backgroundColor: Colors.orange),
          );
        }
        await _loadOrders(null);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        await _loadOrders(null);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _posisiDriver = pos);
      await _loadOrders(pos);
    } catch (e) {
      await _loadOrders(null);
    } finally {
      setState(() => _isLoadingLokasi = false);
    }
  }

  Future<void> _loadOrders(Position? posisi) async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('status', 'menunggu')
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> orders =
          List<Map<String, dynamic>>.from(data);

      // Hitung jarak driver ke setiap order
      if (posisi != null) {
        for (var order in orders) {
          final alamatTujuan = order['alamat_tujuan'] ?? '';
          if (alamatTujuan.isNotEmpty) {
            try {
              final koordinat = await JarakService.getKoordinatPublik(alamatTujuan);
              if (koordinat != null) {
                final jarakM = Geolocator.distanceBetween(
                  posisi.latitude,
                  posisi.longitude,
                  koordinat['lat']!,
                  koordinat['lon']!,
                );
                order['_jarak_driver_km'] = jarakM / 1000;
              }
            } catch (_) {}
          }
        }

        // Urutkan dari yang terdekat
        orders.sort((a, b) {
          final ja = a['_jarak_driver_km'] ?? 999999.0;
          final jb = b['_jarak_driver_km'] ?? 999999.0;
          return ja.compareTo(jb);
        });
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('driver_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            _loadOrders(_posisiDriver);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🛵 Ada order baru masuk!'),
                  backgroundColor: Color(0xFF00B14F),
                ),
              );
            }
          },
        )
        .subscribe();
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
          content: Text('✅ Order berhasil diterima!'),
          backgroundColor: Color(0xFF00B14F),
        ),
      );
      _loadOrders(_posisiDriver);
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

  String _formatJarak(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
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
            icon: const Icon(Icons.list_alt, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverAktifPage())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _ambilLokasidanMuatOrder(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info lokasi driver
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: _posisiDriver != null ? const Color(0xFF00B14F).withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _posisiDriver != null ? Icons.location_on : Icons.location_off,
                  color: _posisiDriver != null ? const Color(0xFF00B14F) : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isLoadingLokasi
                      ? 'Mengambil lokasi...'
                      : _posisiDriver != null
                          ? 'Lokasi aktif • Order diurutkan dari terdekat'
                          : 'Lokasi tidak aktif • Aktifkan GPS untuk urutan terdekat',
                  style: TextStyle(
                    fontSize: 12,
                    color: _posisiDriver != null ? const Color(0xFF00B14F) : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
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
                      final jarakDriver = order['_jarak_driver_km'];
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
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Color(0xFF00B14F), size: 16),
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
                            // Jarak driver ke tujuan
                            if (jarakDriver != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.directions_car, color: Colors.blue, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Jarak dari kamu: ${_formatJarak(jarakDriver)}',
                                    style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
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
                              const Divider(),
                              Text('Total: Rp ${order['total_biaya'].toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B14F)),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
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
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (context) => ChatPage(
                                      orderId: order['id'],
                                      lawanChatNama: 'Warga',
                                    )),
                                  ),
                                  icon: const Icon(Icons.chat_outlined, size: 16),
                                  label: const Text('Chat'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF00B14F),
                                    side: const BorderSide(color: Color(0xFF00B14F)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
