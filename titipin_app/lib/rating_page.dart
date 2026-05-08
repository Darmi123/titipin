import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RatingPage extends StatefulWidget {
  final String orderId;
  final String driverId;
  const RatingPage({super.key, required this.orderId, required this.driverId});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int _rating = 0;
  final _komentarController = TextEditingController();
  bool _isLoading = false;

  Future<void> _kirimRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bintang dulu!'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('ratings').insert({
        'order_id': widget.orderId,
        'driver_id': widget.driverId,
        'warga_id': user!.id,
        'rating': _rating,
        'komentar': _komentarController.text.trim(),
      });
      await Supabase.instance.client.from('orders').update({
        'status': 'selesai',
      }).eq('id', widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⭐ Rating berhasil dikirim!'),
            backgroundColor: Color(0xFF00B14F),
          ),
        );
        Navigator.pop(context);
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
        title: const Text('Beri Rating', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('🛵', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Bagaimana pelayanan driver?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text('Berikan rating untuk membantu driver berkembang',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 48,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _rating == 0 ? 'Tap bintang untuk beri rating'
              : _rating == 1 ? 'Sangat Buruk 😞'
              : _rating == 2 ? 'Buruk 😕'
              : _rating == 3 ? 'Cukup 😐'
              : _rating == 4 ? 'Bagus 😊'
              : 'Sangat Bagus! 🤩',
              style: TextStyle(
                fontSize: 16,
                color: _rating == 0 ? Colors.grey : Colors.amber[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _komentarController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Komentar (opsional)',
                hintText: 'Ceritakan pengalamanmu...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00B14F), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _kirimRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B14F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Kirim Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
