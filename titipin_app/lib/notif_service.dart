import 'dart:convert';
import 'package:http/http.dart' as http;

class NotifService {
  static const String _token = 'zmuJWmZLfutYEkQJemb1';

  static Future<void> kirimNotifDriver({
    required String nomorDriver,
    required String jenisOrder,
    required String alamatAsal,
    required String alamatTujuan,
    required String metodeBayar,
    required double totalBiaya,
  }) async {
    final pesan = '''
🛵 *ORDER BARU TITIPIN!*

📦 Jenis: ${jenisOrder.toUpperCase()}
📍 Dari: $alamatAsal
🏠 Ke: $alamatTujuan
💰 Total: Rp ${totalBiaya.toStringAsFixed(0)}
💳 Bayar: ${metodeBayar.toUpperCase()}

Segera buka aplikasi TitipIn untuk terima order!
''';

    await http.post(
      Uri.parse('https://api.fonnte.com/send'),
      headers: {
        'Authorization': _token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'target': nomorDriver,
        'message': pesan,
      }),
    );
  }
}
