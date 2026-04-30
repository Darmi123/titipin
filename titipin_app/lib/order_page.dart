import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderPage extends StatefulWidget {
  final String jenisOrder;
  const OrderPage({super.key, required this.jenisOrder});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _alamatAsalController = TextEditingController();
  final _alamatTujuanController = TextEditingController();
  final _catatanController = TextEditingController();
  String _metodeBayar = 'cod';
  bool _isLoading = false;

  String get _judulOrder {
    switch (widget.jenisOrder) {
      case 'jastip': return 'Jastip';
      case 'kirim': return 'Kirim Barang';
      case 'jemput': return 'Jemput Barang';
      case 'kurir': return 'Kurir';
      default: return 'Order';
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
        'catatan': _catatanController.text.trim(),
        'metode_bayar': _metodeBayar,
        'status': 'menunggu',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order berhasil dibuat! Menunggu driver...'),
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
                labelText: 'Alamat Asal / Toko',
                prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF00B14F)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _alamatTujuanController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Alamat Tujuan',
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
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
            const SizedBox(height: 24),
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
          ],
        ),
      ),
    );
  }
}
