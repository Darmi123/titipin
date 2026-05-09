import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _namaController = TextEditingController();
  final _noHpController = TextEditingController();
  final _alamatController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _role = '';
  String _email = '';
  double _rataRating = 0;
  int _jumlahRating = 0;
  int _jumlahOrder = 0;
  List<Map<String, dynamic>> _ratings = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      setState(() {
        _namaController.text = data['nama'] ?? '';
        _noHpController.text = data['no_hp'] ?? '';
        _alamatController.text = data['alamat'] ?? '';
        _role = data['role'] ?? '';
        _email = user.email ?? '';
      });

      if (_role == 'driver') {
        await _loadRatingDriver(user.id);
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRatingDriver(String driverId) async {
    final ratings = await Supabase.instance.client
        .from('ratings')
        .select('*, profiles!ratings_warga_id_fkey(nama)')
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);

    final orders = await Supabase.instance.client
        .from('orders')
        .select()
        .eq('driver_id', driverId)
        .eq('status', 'selesai');

    final ratingList = List<Map<String, dynamic>>.from(ratings);
    double total = 0;
    for (var r in ratingList) {
      total += (r['rating'] as num).toDouble();
    }

    setState(() {
      _ratings = ratingList;
      _jumlahRating = ratingList.length;
      _rataRating = ratingList.isEmpty ? 0 : total / ratingList.length;
      _jumlahOrder = (orders as List).length;
    });
  }

  Future<void> _simpanProfil() async {
    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('profiles').update({
        'nama': _namaController.text.trim(),
        'no_hp': _noHpController.text.trim(),
        'alamat': _alamatController.text.trim(),
      }).eq('id', user!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil berhasil disimpan!'),
            backgroundColor: Color(0xFF00B14F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B14F),
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B14F)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B14F).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _namaController.text.isNotEmpty
                              ? _namaController.text[0].toUpperCase()
                              : '?',
                            style: const TextStyle(
                              fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF00B14F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_namaController.text,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _role == 'driver'
                            ? Colors.orange.withOpacity(0.1)
                            : const Color(0xFF00B14F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _role == 'driver' ? '🛵 Driver' : '🏠 Warga',
                          style: TextStyle(
                            color: _role == 'driver' ? Colors.orange : const Color(0xFF00B14F),
                            fontWeight: FontWeight.bold, fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                if (_role == 'driver') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Statistik Driver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(_rataRating.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(5, (i) => Icon(
                                        i < _rataRating.round() ? Icons.star : Icons.star_border,
                                        color: Colors.amber, size: 14,
                                      )),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('$_jumlahRating ulasan', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B14F).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text('$_jumlahOrder',
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00B14F)),
                                    ),
                                    const Icon(Icons.delivery_dining, color: Color(0xFF00B14F), size: 20),
                                    const SizedBox(height: 4),
                                    const Text('Order selesai', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_ratings.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Ulasan Terbaru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ..._ratings.take(3).map((r) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(r['profiles']?['nama'] ?? 'Warga',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: List.generate(5, (i) => Icon(
                                        i < (r['rating'] as num).toInt() ? Icons.star : Icons.star_border,
                                        color: Colors.amber, size: 14,
                                      )),
                                    ),
                                  ],
                                ),
                                if (r['komentar'] != null && r['komentar'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(r['komentar'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: const Icon(Icons.person_outlined, color: Color(0xFF00B14F)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noHpController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'No. HP',
                          prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF00B14F)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _alamatController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Alamat Rumah',
                          prefixIcon: const Icon(Icons.home_outlined, color: Color(0xFF00B14F)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _simpanProfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B14F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Keluar', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }
}
