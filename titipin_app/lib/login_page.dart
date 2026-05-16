import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'services/notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  Future<void> _masuk() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      NotificationService().init();
      if (mounted) {
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email atau password salah!'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Bagian atas - hijau dengan logo
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
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
                  Image.network(
                    'https://taqaukbucwkyfhdlytqt.supabase.co/storage/v1/object/public/assets/IMG-20260515-WA0003.jpg',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 180, height: 180,
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Mager? titipin aja.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),

          // Bagian bawah - form login
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('Masuk', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Selamat datang kembali!', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 28),

                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00B14F)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00B14F), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00B14F)),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00B14F), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Tombol masuk
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _masuk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B14F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Masuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Daftar
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14),
                            children: [
                              TextSpan(text: 'Belum punya akun? ', style: TextStyle(color: Colors.grey)),
                              TextSpan(text: 'Daftar', style: TextStyle(color: Color(0xFF00B14F), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
