import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notif_service.dart';
import 'services/notification_service.dart';

class OrderPage extends StatefulWidget {
  final String jenisOrder;
  final String? namaTokoAwal;
  const OrderPage({super.key, required this.jenisOrder, this.namaTokoAwal});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late TextEditingController _alamatAsalController;
  final _catatanController = TextEditingController();
  String _metodeBayar = 'cod';
  bool _isLoading = false;
  double _jarak = 0;
  double _ongkir = 0;
  final double _jasaTitip = 2000;
  String? _desaTerpilih;

  final List<Map<String, dynamic>> _daftarDesa = [
    {'nama': 'Bojong', 'jarak': 1.0},
    {'nama': 'Babakan', 'jarak': 2.0},
    {'nama': 'Tuwel', 'jarak': 3.2},
    {'nama': 'Kemaron', 'jarak': 6.0},
    {'nama': 'Pekandangan', 'jarak': 7.6},
    {'nama': 'Guci', 'jarak': 8.0},
    {'nama': 'Bumijawa', 'jarak': 11.0},
    {'nama': 'Buniwah', 'jarak': 2.0},
    {'nama': 'Karang Jambu', 'jarak': 4.5},
    {'nama': 'Cilongok', 'jarak': 11.0},
    {'nama': 'Lengkong', 'jarak': 3.0},
    {'nama': 'Batunyana', 'jarak': 4.5},
    {'nama': 'Praban', 'jarak': 7.3},
    {'nama': 'Cikura', 'jarak': 10.0},
    {'nama': 'Rembul', 'jarak': 6.0},
    {'nama': 'Kedawung', 'jarak': 8.0},
    {'nama': 'Simpar', 'jarak': 8.6},
  ];

  String get _judulOrder {
    switch (widget.jenisOrder) {
      case 'jastip': return 'Jastip';
      case 'kirim': return 'Kirim Barang';
      case 'jemput': return 'Jemput Barang';
      case 'kurir': return 'Kurir';
      default: return 'Order';
    }
  }

  @override
  void initState() {
    super.initState();
    _alamatAsalController = TextEditingController(text: widget.namaTokoAwal ?? '');
  }

  void _pilihDesa(String? nama) {
    if (nama == null) return;
    final desa = _daftarDesa.firstWhere((d) => d['nama'] == nama);
    setState(() {
      _desaTerpilih = nama;
      _jarak = desa['jarak'];
      _ongkir = _jarak * 2500 + 2000;
    });
  }

  Future<void> _buatOrder() async {
    if (_alamatAsalController.text.isEmpty || _desaTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi alamat asal dan pilih desa tujuan!'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final orderData = await Supabase.instance.client.from('orders').insert({
        'warga_id': user!.id,
        'jenis': widget.jenisOrder,
        'alamat_asal': _alamatAsalController.text.trim(),
        'alamat_tujuan': 'Desa $_desaTerpilih',
        'jarak_km': _jarak,
        'catatan': _catatanController.text.trim(),
        'metode_bayar': _metodeBayar,
        'total_biaya': _ongkir + _jasaTitip,
        'status': 'menunggu',
      }).select().single();
      final orderId = orderData['id'] as String;
      // Ambil semua driver aktif
      final drivers = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('role', 'driver');
      for (final driver in drivers) {
        await NotificationService().notifyDriverNewOrder(
          driverId: driver['id'] as String,
          orderId: orderId,
          orderInfo: '${widget.jenisOrder} → Desa $_desaTerpilih',
        );
      }
      await NotifService.kirimNotifDriver(
        nomorDriver: '6285156411914',
        jenisOrder: widget.jenisOrder,
        alamatAsal: _alamatAsalController.text.trim(),
        alamatTujuan: 'Desa $_desaTerpilih',
        metodeBayar: _metodeBayar,
        totalBiaya: _ongkir + _jasaTitip,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order berhasil dibuat! Driver akan segera dihubungi.'),
            backgroundColor: Color(0xFF00B14F),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B14F),
        title: Text(_judulOrder, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detail Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _alamatAsalController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Nama Toko / Alamat Asal',
                prefixIcon: const Icon(Icons.store_outlined, color: Color(0xFF00B14F)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _desaTerpilih,
                        hint: const Text('Pilih Desa Tujuan'),
                        isExpanded: true,
                        items: _daftarDesa.map((desa) {
                          return DropdownMenuItem<String>(
                            value: desa['nama'],
                            child: Text('${desa['nama']} (${desa['jarak']} km)'),
                          );
                        }).toList(),
                        onChanged: _pilihDesa,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_jarak > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B14F).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00B14F).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rincian Biaya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _biayaRow('Jarak', '$_jarak km'),
                    _biayaRow('Ongkir (Rp 2.500/km + Rp 2.000)', 'Rp ${_ongkir.toStringAsFixed(0)}'),
                    _biayaRow('Jasa Titip', 'Rp ${_jasaTitip.toStringAsFixed(0)}'),
                    const Divider(),
                    _biayaRow('Total', 'Rp ${(_ongkir + _jasaTitip).toStringAsFixed(0)}', bold: true),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _catatanController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Metode Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _metodeBayar = 'cod'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _metodeBayar == 'cod' ? const Color(0xFF00B14F) : Colors.white,
                        border: Border.all(color: const Color(0xFF00B14F)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text('💵 COD',
                          style: TextStyle(
                            color: _metodeBayar == 'cod' ? Colors.white : const Color(0xFF00B14F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _metodeBayar = 'transfer'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _metodeBayar == 'transfer' ? const Color(0xFF00B14F) : Colors.white,
                        border: Border.all(color: const Color(0xFF00B14F)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text('🏦 Transfer',
                          style: TextStyle(
                            color: _metodeBayar == 'transfer' ? Colors.white : const Color(0xFF00B14F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _buatOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B14F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Buat Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _biayaRow(String label, String nilai, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
          Text(nilai, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: bold ? const Color(0xFF00B14F) : null)),
        ],
      ),
    );
  }
}
