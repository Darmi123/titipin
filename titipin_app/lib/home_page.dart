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
import 'screens/notification_screen.dart';

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
    {'nama': 'Seblak Station', 'kategori': 'Makanan dan Minuman', 'icon': '🥘', 'status': 'BUKA', 'jarak': '± 300 m', 'desc': 'Makanan pedas favorit warga'},
    {'nama': 'Pasar Bojong', 'kategori': 'Sembako', 'icon': '🛒', 'status': 'BUKA', 'jarak': '± 450 m', 'desc': 'Sembako & kebutuhan rumah'},
    {'nama': 'Supeno Kopi Buniwah', 'kategori': 'Minuman & Camilan', 'icon': '🥤', 'status': 'BUKA', 'jarak': '± 600 m', 'desc': 'Minuman & camilan'},
    {'nama': 'Apotek Asyifa', 'kategori': 'Obat & Kesehatan', 'icon': '💊', 'status': 'BUKA', 'jarak': '± 800 m', 'desc': 'Obat & kesehatan terpercaya'},
    {'nama': 'Toko Madura', 'kategori': 'Sembako', 'icon': '🛍️', 'status': 'TUTUP', 'jarak': '± 1 km', 'desc': 'Sembako lengkap'},
    {'nama': 'Pentol Sakti Bojong', 'kategori': 'Makanan', 'icon': '🍱', 'status': 'BUKA', 'jarak': '± 1.2 km', 'desc': 'Jajanan favorit anak-anak'},
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
      if (mounted) {
        setState(() {
          _nama = data['nama'] ?? '';
          _role = data['role'] ?? 'warga';
        });
      }
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
    final pages = _role == 'driver'
        ? [_buildDriverHome(), const DriverPage(), const RiwayatChatPage(), const ProfilPage()]
        : [_buildWargaHome(), const RiwayatPage(), const RiwayatChatPage(), const ProfilPage()];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _role != 'driver' ? FloatingActionButton(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => const OrderPage(jenisOrder: 'Jastip')),
        ),
        backgroundColor: const Color(0xFF00B14F),
        shape: const CircleBorder(),
        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 30),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav() {
    if (_role == 'driver') {
      return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00B14F),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Akun'),
        ],
      );
    }

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_outlined, Icons.home, 'Beranda'),
          _navItem(1, Icons.receipt_long_outlined, Icons.receipt_long, 'Pesanan'),
          const SizedBox(width: 40),
          _navItem(2, Icons.chat_outlined, Icons.chat, 'Chat'),
          _navItem(3, Icons.person_outline, Icons.person, 'Akun'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? activeIcon : icon, color: isActive ? const Color(0xFF00B14F) : Colors.grey),
          Text(label, style: TextStyle(fontSize: 11, color: isActive ? const Color(0xFF00B14F) : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWargaHome() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF00B14F), size: 16),
                            const SizedBox(width: 4),
                            const Text('Desa Bojong', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00B14F))),
                            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00B14F), size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            TextSpan(text: 'Hai, $_nama! ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const TextSpan(text: '👋', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                      ),
                      const Text('Mager? titipin aja. Kami yang beliin & antar.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Image.network(
                  'https://taqaukbucwkyfhdlytqt.supabase.co/storage/v1/object/public/assets/IMG-20260515-WA0002.jpg',
                  width: 70, height: 70, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.delivery_dining, size: 40, color: Color(0xFF00B14F)),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'https://taqaukbucwkyfhdlytqt.supabase.co/storage/v1/object/public/assets/IMG-20260515-WA0000.jpg',
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B14F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: CircularProgressIndicator(color: Color(0xFF00B14F))),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Layanan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      _layananItem('🛒', 'Belanja\nKebutuhan', 'Harian', 'Belanja Kebutuhan', const Color(0xFFE8F5E9)),
                      _layananItem('🍔', 'Makanan &\nMinuman', 'Cepat saji, jajan', 'Makanan & Minuman', const Color(0xFFFFF3E0)),
                      _layananItem('💊', 'Obat &\nKesehatan', 'Aman & asli', 'Obat & Kesehatan', const Color(0xFFE3F2FD)),
                      _layananItem('📦', 'Titip Barang\n& Dokumen', 'Aman sampai tujuan', 'Titip Barang', const Color(0xFFFCE4EC)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cara pakai
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cara pakai TitipIn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Lihat semua ›', style: TextStyle(fontSize: 13, color: const Color(0xFF00B14F), fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      _caraItem('1', '📱', 'Pesan', 'Pilih barang, tulis alamat, dan kirim pesanan.'),
                      _arrow(),
                      _caraItem('2', '🛒', 'Kami belikan', 'TitipIn belikan pesananmu dengan teliti.'),
                      _arrow(),
                      _caraItem('3', '🛵', 'Diantar', 'Kami antar langsung sampai depan rumahmu.'),
                      _arrow(),
                      _caraItem('4', '🏠', 'Selesai', 'Pesanan diterima, kamu tinggal terima beres.'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Toko terdekat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Toko terdekat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Lihat semua ›', style: TextStyle(fontSize: 13, color: const Color(0xFF00B14F), fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tokoRekomendasi.length,
                    itemBuilder: (context, index) {
                      final toko = _tokoRekomendasi[index];
                      final isBuka = toko['status'] == 'BUKA';
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
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
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: isBuka ? const Color(0xFF00B14F) : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(child: Text(toko['icon'], style: const TextStyle(fontSize: 22))),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isBuka ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(toko['status'],
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isBuka ? Colors.green : Colors.red),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(toko['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(toko['jarak'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(toko['desc'], style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Butuh bantuan
                Container(
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
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.headset_mic, color: Color(0xFF00B14F)),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: 14),
                          children: [
                            TextSpan(text: 'Butuh bantuan?\n'),
                            TextSpan(text: 'Chat admin TitipIn', style: TextStyle(color: Color(0xFF00B14F), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverHome() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          backgroundColor: const Color(0xFF00B14F),
          automaticallyImplyLeading: false,
          actions: [
            const NotificationBadge(),
            IconButton(
              icon: const Icon(Icons.delivery_dining, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPage())),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00B14F), Color(0xFF007A36)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Hai, $_nama Driver! 👋',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text('Mager? titipin aja. Kami yang beliin & antar.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'https://taqaukbucwkyfhdlytqt.supabase.co/storage/v1/object/public/assets/IMG-20260515-WA0000.jpg',
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _layananItem(String icon, String label, String sub, String jenisOrder, Color bgColor) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => OrderPage(jenisOrder: jenisOrder)),
        ),
        child: Column(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _caraItem(String step, String icon, String title, String desc) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: Color(0xFF00B14F), shape: BoxShape.circle),
            child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          ),
          const SizedBox(height: 4),
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(desc, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center, maxLines: 3),
        ],
      ),
    );
  }

  Widget _arrow() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
    );
  }
}
