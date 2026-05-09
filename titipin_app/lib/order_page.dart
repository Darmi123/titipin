import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notif_service.dart';
import 'jarak_service.dart';

class OrderPage extends StatefulWidget {
  final String jenisOrder;
  final String? namaTokoAwal;
  const OrderPage({super.key, required this.jenisOrder, this.namaTokoAwal});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late TextEditingController _alamatAsalController;
  final _alamatTujuanController = TextEditingController();
  final _catatanController = TextEditingController();
  String _metodeBayar = 'cod';
  bool _isLoading = false;
  bool _isHitungJarak = false;
  double _jarak = 0;
  double _ongkir = 0;
  double _jasaTitip = 2000;
  String _errorJarak = '';

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

  Future<void> _hitungJarak() async {
    if (_alamatAsalController.text.isEmpty || _alamatTujuanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi alamat asal dan tujuan dulu!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isHitungJarak = true;
      _errorJarak = '';
    });

    final hasil = await JarakService.hitungJarak(
      alamatAsal: _alamatAsalController.text.trim(),
      alamatTujuan: _alamatTujuanController.text.trim(),
    );

    if (hasil.containsKey('error')) {
      setState(() {
        _errorJarak = hasil['error'];
        _isHitungJarak = false;
      });
    } else {
      setState(() {
        _jarak = hasil['jarak_km'];
        _ongkir = hasil['ongkir'];
        _isHitungJarak = false;
      });
    }
  }

  Future<void> _buatOrder() async {
    if (_alamatAsalController.text.isEmpty || _alamatTujuanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat asal dan tujuan wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('orders').insert({
        'warga_id': user!.id,
        'jenis': widget.jenisOrder,
        'alamat_asal': _alamatAsalController.text.trim(),
        'alamat_tujuan': _alamatTujuanController.text.trim(),
        'jarak_km': _jarak,
        'catatan': _catatanController.text.trim(),
        'metode_bayar': _metodeBayar,
        'total_biaya': _jarak > 0 ? _ongkir + _jasaTitip : null,
        'status': 'menunggu',
      });
      await NotifService.kirimNotifDriver(
        nomorDriver: '6285156411914',
        jenisOrder: widget.jenisOrder,
        alamatAsal: _alamatAsalController.text.trim(),
        alamatTujuan: _alamatTujuanController.text.trim(),
        metodeBayar: _metodeBayar,
        totalBiaya: _jarak > 0 ? _ongkir + _jasaTitip : 0,
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
            TextField(
              controller: _alamatTujuanController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Alamat Tujuan',
                hintText: 'Contoh: Desa Bojong RT 01 RW 02',
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isHitungJarak ? null : _hitungJarak,
                icon: _isHitungJarak
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.calculate_outlined),
                label: Text(_isHitungJarak ? 'Menghitung jarak...' : 'Hitung Jarak & Ongkir Otomatis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B14F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_errorJarak.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorJarak, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ],
                ),
              ),
            ],
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
                    _biayaRow('Jarak', '${_jarak.toStringAsFixed(1)} km'),
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
