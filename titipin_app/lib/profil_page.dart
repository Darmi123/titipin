import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'riwayat_page.dart';

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
  bool _isUploadingFoto = false;
  String? _fotoUrl;
  String _role = '';
  String _email = '';
  double _rataRating = 0;
  int _jumlahRating = 0;
  int _jumlahOrder = 0;
  int _jumlahOrderWarga = 0;
  List<Map<String, dynamic>> _ratings = [];

  String get _statusMember {
    if (_jumlahOrderWarga >= 20) return 'VIP 👑';
    if (_jumlahOrderWarga >= 10) return 'Setia ⭐';
    return 'Baru 🌱';
  }

  Color get _statusColor {
    if (_jumlahOrderWarga >= 20) return Colors.purple;
    if (_jumlahOrderWarga >= 10) return Colors.orange;
    return const Color(0xFF00B14F);
  }

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
        _fotoUrl = data['foto_url'];
      });
      if (_role == 'driver') {
        await _loadRatingDriver(user.id);
      } else {
        await _loadOrderWarga(user.id);
      }
      setState(() => _isLoading = false);
    }
  }


  Future<void> _uploadFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _isUploadingFoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final user = Supabase.instance.client.auth.currentUser!;
      final ext = picked.name.split('.').last;
      final path = '\${user.id}.\$ext';
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);
      await Supabase.instance.client.from('profiles')
          .update({'foto_url': url}).eq('id', user.id);
      setState(() => _fotoUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil diperbarui!'), backgroundColor: Color(0xFF00B14F)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isUploadingFoto = false);
    }
  }

  Future<void> _loadOrderWarga(String wargaId) async {
    final orders = await Supabase.instance.client
        .from('orders')
        .select()
        .eq('warga_id', wargaId);
    setState(() => _jumlahOrderWarga = (orders as List).length);
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
          const SnackBar(content: Text('✅ Profil berhasil disimpan!'), backgroundColor: Color(0xFF00B14F)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B14F)))
          : CustomScrollView(
              slivers: [
                // Header dengan gradient
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: const Color(0xFF00B14F),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00B14F), Color(0xFF007A36)],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Avatar
                          GestureDetector(
                            onTap: _uploadFoto,
                            child: Stack(
                              children: [
                                Container(
                                  width: 90, height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: _isUploadingFoto
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : ClipOval(
                                        child: _fotoUrl != null
                                          ? Image.network(_fotoUrl!, fit: BoxFit.cover, width: 90, height: 90)
                                          : Center(
                                              child: Text(
                                                _namaController.text.isNotEmpty
                                                    ? _namaController.text[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                      ),
                                ),
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: Container(
                                    width: 28, height: 28,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF00B14F)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(_namaController.text,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _role == 'driver' ? '🛵 Driver' : '🏠 Warga',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [

                        // Status Member (untuk warga)
                        if (_role != 'driver') ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: _statusColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _jumlahOrderWarga >= 20 ? '👑' : _jumlahOrderWarga >= 10 ? '⭐' : '🌱',
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Member $_statusMember',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _statusColor),
                                      ),
                                      Text('$_jumlahOrderWarga order dilakukan',
                                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: _jumlahOrderWarga >= 20 ? 1.0 : _jumlahOrderWarga / 20,
                                          backgroundColor: Colors.grey.withOpacity(0.2),
                                          color: _statusColor,
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _jumlahOrderWarga >= 20
                                            ? 'Level maksimal!'
                                            : _jumlahOrderWarga >= 10
                                                ? '${20 - _jumlahOrderWarga} order lagi untuk VIP'
                                                : '${10 - _jumlahOrderWarga} order lagi untuk Setia',
                                        style: TextStyle(fontSize: 11, color: _statusColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Riwayat Order shortcut
                          _menuTile(
                            icon: Icons.receipt_long_outlined,
                            label: 'Riwayat Order',
                            sub: '$_jumlahOrderWarga order',
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RiwayatPage()),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Statistik driver
                        if (_role == 'driver') ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Statistik Driver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _statBox(
                                      value: _rataRating.toStringAsFixed(1),
                                      label: '$_jumlahRating ulasan',
                                      icon: Icons.star,
                                      color: Colors.amber,
                                      isRating: true,
                                      rating: _rataRating,
                                    )),
                                    const SizedBox(width: 12),
                                    Expanded(child: _statBox(
                                      value: '$_jumlahOrder',
                                      label: 'Order selesai',
                                      icon: Icons.delivery_dining,
                                      color: const Color(0xFF00B14F),
                                    )),
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
                                            Row(children: List.generate(5, (i) => Icon(
                                              i < (r['rating'] as num).toInt() ? Icons.star : Icons.star_border,
                                              color: Colors.amber, size: 14,
                                            ))),
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
                          const SizedBox(height: 12),
                        ],

                        // Info Akun
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Edit Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 16),
                              _inputField(_namaController, 'Nama Lengkap', Icons.person_outlined),
                              const SizedBox(height: 12),
                              _inputField(_noHpController, 'No. HP', Icons.phone_outlined, type: TextInputType.phone),
                              const SizedBox(height: 12),
                              _inputField(_alamatController, 'Alamat Rumah', Icons.home_outlined, maxLines: 3),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
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
                        const SizedBox(height: 12),

                        // Logout
                        SizedBox(
                          width: double.infinity,
                          height: 50,
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
                ),
              ],
            ),
    );
  }

  Widget _menuTile({required IconData icon, required String label, required String sub, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00B14F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF00B14F)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _statBox({required String value, required String label, required IconData icon, required Color color, bool isRating = false, double rating = 0}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          if (isRating)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Icon(
                i < rating.round() ? Icons.star : Icons.star_border,
                color: color, size: 14,
              )),
            )
          else
            Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00B14F)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00B14F), width: 2),
        ),
      ),
    );
  }
}
