import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semua kolom harus diisi!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFFEE5D50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password minimal harus 6 karakter!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFFEE5D50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konfirmasi password tidak cocok!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFFEE5D50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? error = await AuthService().register(name, email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi Berhasil! Silakan Login.', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $error', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFFEE5D50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF2B3674);
    const accentIndigo = Color(0xFF4318FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Daftar Akun Admin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Buat akun administrator untuk mengelola data KostKu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFFA3AED0),
                  ),
                ),
                const SizedBox(height: 28),

                // Name Input
                Text('Nama Lengkap', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: primaryNavy)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                    decoration: const InputDecoration(
                      hintText: 'Admin Kost Zazin',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFFA3AED0), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Email Input
                Text('Email', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: primaryNavy)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                    decoration: const InputDecoration(
                      hintText: 'admin@kostku.com',
                      prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFA3AED0), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Password Input
                Text('Password', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: primaryNavy)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                    decoration: InputDecoration(
                      hintText: 'Minimal 6 karakter',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFA3AED0), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFFA3AED0),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Confirm Password Input
                Text('Konfirmasi Password', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: primaryNavy)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                    decoration: InputDecoration(
                      hintText: 'Ulangi password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFFA3AED0), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFFA3AED0),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Register Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryNavy.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text('Daftar Akun', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sudah punya akun? ', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFA3AED0), fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Masuk di sini', style: GoogleFonts.plusJakartaSans(color: accentIndigo, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
