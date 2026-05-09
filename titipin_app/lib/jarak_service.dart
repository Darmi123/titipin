import 'dart:convert';
import 'package:http/http.dart' as http;

class JarakService {
  static Future<Map<String, dynamic>> hitungJarak({
    required String alamatAsal,
    required String alamatTujuan,
  }) async {
    try {
      // Geocode alamat asal
      final koordinatAsal = await _getKoordinat(alamatAsal);
      if (koordinatAsal == null) return {'error': 'Alamat asal tidak ditemukan'};

      // Geocode alamat tujuan
      final koordinatTujuan = await _getKoordinat(alamatTujuan);
      if (koordinatTujuan == null) return {'error': 'Alamat tujuan tidak ditemukan'};

      // Hitung jarak dengan OSRM
      final jarak = await _hitungJarakOSRM(koordinatAsal, koordinatTujuan);
      
      return {
        'jarak_km': jarak,
        'ongkir': jarak * 2500 + 2000,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, double>?> _getKoordinat(String alamat) async {
    final query = Uri.encodeComponent('$alamat, Jawa Tengah, Indonesia');
    final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'TitipInApp/1.0'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return {
          'lat': double.parse(data[0]['lat']),
          'lon': double.parse(data[0]['lon']),
        };
      }
    }
    return null;
  }

  static Future<double> _hitungJarakOSRM(
    Map<String, double> asal,
    Map<String, double> tujuan,
  ) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${asal['lon']},${asal['lat']};${tujuan['lon']},${tujuan['lat']}'
        '?overview=false';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 'Ok') {
        final jarakMeter = data['routes'][0]['distance'] as num;
        return jarakMeter / 1000; // Convert ke km
      }
    }
    
    // Fallback: hitung jarak lurus (Haversine)
    return _hitungHaversine(asal, tujuan);
  }

  static double _hitungHaversine(
    Map<String, double> asal,
    Map<String, double> tujuan,
  ) {
    const r = 6371.0;
    final dLat = _toRad(tujuan['lat']! - asal['lat']!);
    final dLon = _toRad(tujuan['lon']! - asal['lon']!);
    final a = _sin2(dLat / 2) +
        _cos(_toRad(asal['lat']!)) *
        _cos(_toRad(tujuan['lat']!)) *
        _sin2(dLon / 2);
    final c = 2 * _asin(_sqrt(a));
    return r * c;
  }

  static double _toRad(double deg) => deg * 3.14159265358979 / 180;
  static double _sin2(double x) => _sin(x) * _sin(x);
  static double _sin(double x) => x - x*x*x/6 + x*x*x*x*x/120;
  static double _cos(double x) => 1 - x*x/2 + x*x*x*x/24;
  static double _asin(double x) => x + x*x*x/6 + 3*x*x*x*x*x/40;
  static double _sqrt(double x) {
    if (x == 0) return 0;
    double z = x;
    for (int i = 0; i < 10; i++) z = (z + x/z) / 2;
    return z;
  }
}
