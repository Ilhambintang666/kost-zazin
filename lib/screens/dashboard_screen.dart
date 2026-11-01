import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_tab_screen.dart';
import 'kamar_screen.dart';
import 'pembayaran_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeTabScreen(),
    KamarScreen(),
    PembayaranScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    'KostKu Le',
    'Manajemen Kamar',
    'Pembayaran & Tagihan',
    'Profil Admin',
  ];

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF2B3674);
    const accentIndigo = Color(0xFF4318FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.plusJakartaSans(
            color: primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, color: primaryNavy, size: 20),
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // Floating Modern Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFF4F7FE), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x141B254B),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.grid_view_rounded, 'Home', accentIndigo),
                  _buildNavItem(1, Icons.meeting_room_rounded, 'Kamar', accentIndigo),
                  _buildNavItem(2, Icons.account_balance_wallet_rounded, 'Bayar', accentIndigo),
                  _buildNavItem(3, Icons.person_rounded, 'Profil', accentIndigo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color accentColor) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? accentColor : const Color(0xFFA3AED0),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}