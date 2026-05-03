import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotifService {
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

Segera buka aplikasi TitipIn untuk terima order!''';

    await Supabase.instance.client.functions.invoke(
      'kirim-notif',
      body: {
        'nomorDriver': nomorDriver,
        'pesan': pesan,
      },
    );
  }
}
