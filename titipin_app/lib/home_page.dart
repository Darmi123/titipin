import 'widgets/notification_badge.dart';
import 'services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'order_page.dart';
import 'riwayat_page.dart';
import 'driver_page.dart';
import 'chat_page.dart';
import 'riwayat_chat_page.dart';
import 'profil_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _nama = '';
  String _role = 'warga';
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _tokoRekomendasi = [
    {'nama': 'Seblak Station', 'kategori': 'Makanan dan Minuman', 'icon': '🥘', 'status': 'BUKA'},
    {'nama': 'Pasar Bojong', 'kategori': 'Sembako', 'icon': '🛒', 'status': 'BUKA'},
    {'nama': 'Supeno Kopi Buniwah', 'kategori': 'Minuman & Camilan', 'icon': '🥤', 'status': 'BUKA'},
    {'nama': 'Apotek Asyifa', 'kategori': 'Obat & Kesehatan', 'icon': '💊', 'status': 'BUKA'},
    {'nama': 'Toko Madura', 'kategori': 'Sembako', 'icon': '🛍️', 'status': 'TUTUP'},
    {'nama': 'Pentol Sakti Bojong', 'kategori': 'Makanan', 'icon': '🍱', 'status': 'BUKA'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    NotificationService().init();
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
        _nama = data['nama'] ?? '';
        _role = data['role'] ?? 'warga';
      });
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00B14F), Color(0xFF007A35)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.orange, size: 16),
                                const SizedBox(width: 4),
                                const Text('Desa Bojong',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const NotificationBadge(),
                          if (_role == 'driver')
                            IconButton(
                              icon: const Icon(Icons.delivery_dining, color: Colors.white),
                              onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (context) => const DriverPage()),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: _logout,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Hai, $_nama! 👋\n',
                              style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
                              ),
                            ),
                            const TextSpan(
                              text: 'Mager? titipin aja. Kami yang beliin & antar.',
                              style: TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Banner Promo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('PROMO LAUNCHING!',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Diskon Ongkir 50%',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const Text('SEMUA ORDER – MINGGU INI SAJA!',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Text('🛵', style: TextStyle(fontSize: 48)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu Kategori
                  const Text('Layanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _kategoriCard('🛒', 'Belanja\nKebutuhan', 'jastip'),
                      _kategoriCard('🥤', 'Makanan &\nMinuman', 'jastip'),
                      _kategoriCard('💊', 'Obat &\nKesehatan', 'jastip'),
                      _kategoriCard('📦', 'Titip\nBarang', 'kirim'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Cara Pakai
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cara pakai TitipIn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {},
                        child: Text('Lihat semua', style: TextStyle(color: Colors.green[700], fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _caraPakaiCard('📱', '1. Pesan', 'Pilih barang, tulis alamat, dan kirim pesanan.'),
                        _caraPakaiCard('🛒', '2. Kami belikan', 'TitipIn belikan pesananmu dengan teliti.'),
                        _caraPakaiCard('🛵', '3. Diantar', 'Kami antar langsung sampai depan rumahmu.'),
                        _caraPakaiCard('🏠', '4. Selesai', 'Pesanan diterima, kamu tinggal terima beres.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Toko Rekomendasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Toko Rekomendasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {},
                        child: Text('Lihat semua', style: TextStyle(color: Colors.green[700], fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tokoRekomendasi.length,
                    itemBuilder: (context, index) {
                      final toko = _tokoRekomendasi[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => OrderPage(
                            jenisOrder: 'jastip',
                            namaTokoAwal: toko['nama'],
                          )),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B14F).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(child: Text(toko['icon'], style: const TextStyle(fontSize: 24))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(toko['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(toko['kategori'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: toko['status'] == 'BUKA'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(toko['status'],
                                  style: TextStyle(
                                    color: toko['status'] == 'BUKA' ? Colors.green : Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Bantuan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Butuh bantuan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Chat admin TitipIn', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Chat', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home, 'Beranda', 0),
                _navItem(Icons.receipt_long_outlined, 'Pesanan', 1),
                _navItemUtama(),
                _navItem(Icons.chat_outlined, 'Chat', 3),
                _navItem(Icons.person_outlined, 'Akun', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatChatPage()));
        } else if (index == 4) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilPage()));
        } else if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPage()));
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF00B14F) : Colors.grey, size: 24),
          Text(label, style: TextStyle(fontSize: 11, color: isActive ? const Color(0xFF00B14F) : Colors.grey)),
        ],
      ),
    );
  }

  Widget _navItemUtama() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (context) => const OrderPage(jenisOrder: 'jastip')),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00B14F), Color(0xFFFF6B00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _kategoriCard(String emoji, String label, String jenis) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (context) => OrderPage(jenisOrder: jenis)),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _caraPakaiCard(String emoji, String judul, String deskripsi) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(deskripsi, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
