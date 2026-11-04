import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF2B3674);
    const accentIndigo = Color(0xFF4318FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        child: Column(
          children: [
            // Center Profile Avatar with Glowing Ring
            StreamBuilder<DocumentSnapshot>(
              stream: currentUser != null
                  ? FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots()
                  : null,
              builder: (context, snapshot) {
                String name = 'Admin Kost';
                String email = currentUser?.email ?? 'admin@kostku.com';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    name = data['name'] ?? name;
                    email = data['email'] ?? email;
                  }
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [primaryNavy, accentIndigo],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentIndigo.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: const Color(0xFFF4F7FE),
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 46,
                            color: primaryNavy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryNavy,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: accentIndigo),
                          onPressed: () => _editProfileName(name),
                          tooltip: 'Ubah Nama',
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        email,
                        style: GoogleFonts.plusJakartaSans(
                          color: accentIndigo,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Unified White Settings Container (iOS Style)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x081B254B),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsRow(
                    icon: Icons.verified_user_rounded,
                    title: 'Role Akun',
                    subtitle: 'Administrator Kost',
                    trailing: const Icon(Icons.verified_rounded, color: accentIndigo, size: 20),
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFF4F7FE)),
                  _buildSettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Versi Aplikasi',
                    subtitle: 'KostKu v1.0.0 (Production Ready)',
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFF4F7FE)),
                  _buildSettingsRow(
                    icon: Icons.security_rounded,
                    title: 'Keamanan Database',
                    subtitle: 'Firebase Authentication & Cloud Firestore',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Red-Tinted Logout Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFB91C1C)),
                label: Text(
                  'Keluar (Logout)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    const primaryNavy = Color(0xFF2B3674);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: primaryNavy, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: primaryNavy,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFA3AED0)),
      ),
      trailing: trailing,
    );
  }

  void _editProfileName(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Ubah Nama Profil', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nama lengkap Anda',
            labelText: 'Nama Lengkap',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && currentUser != null) {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
                  'name': newName,
                }, SetOptions(merge: true));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFB91C1C), size: 26),
              const SizedBox(width: 10),
              Text('Konfirmasi Logout', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari akun admin KostKu?',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _authService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
