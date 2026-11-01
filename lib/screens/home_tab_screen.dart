import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/room.dart';

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  String _formatRupiah(double amount) {
    try {
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      return formatter.format(amount);
    } catch (_) {
      return 'Rp ${amount.toInt()}';
    }
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF2B3674);
    const accentIndigo = Color(0xFF4318FF);
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Welcome Card with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryNavy, accentIndigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: accentIndigo.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang 👋',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kelola operasional & penghuni KostKu secara praktis dan terorganisir',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bento Grid Title
            Text(
              'Ringkasan Bisnis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryNavy,
              ),
            ),
            const SizedBox(height: 14),

            // Bento Grid (2x2 Layout)
            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('rooms').snapshots(),
              builder: (context, roomSnap) {
                int totalRooms = 0;
                int occupiedRooms = 0;
                int availableRooms = 0;
                int overdueCount = 0;

                if (roomSnap.hasData) {
                  totalRooms = roomSnap.data!.docs.length;
                  for (var doc in roomSnap.data!.docs) {
                    final r = Room.fromFirestore(doc);
                    if (r.isOccupied) {
                      occupiedRooms++;
                      if (r.isOverdue) overdueCount++;
                    } else {
                      availableRooms++;
                    }
                  }
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('payments').snapshots(),
                  builder: (context, paySnap) {
                    double monthlyRevenue = 0;
                    final now = DateTime.now();

                    if (paySnap.hasData) {
                      for (var doc in paySnap.data!.docs) {
                        final p = Payment.fromFirestore(doc);
                        if (p.status == 'Lunas' &&
                            p.paymentDate.month == now.month &&
                            p.paymentDate.year == now.year) {
                          monthlyRevenue += p.amount;
                        }
                      }
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildBentoCard(
                                title: 'Total Kamar',
                                value: '$totalRooms',
                                subtitle: 'Kapasitas Kost',
                                icon: Icons.meeting_room_rounded,
                                color: primaryNavy,
                                bgColor: const Color(0xFFF4F7FE),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBentoCard(
                                title: 'Kamar Terisi',
                                value: '$occupiedRooms',
                                subtitle: '$availableRooms Kamar Kosong',
                                icon: Icons.person_pin_rounded,
                                color: const Color(0xFFB45309),
                                bgColor: const Color(0xFFFEF3C7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBentoCard(
                                title: 'Pemasukan Bulan Ini',
                                value: _formatRupiah(monthlyRevenue),
                                subtitle: 'Total Terbayar',
                                icon: Icons.account_balance_wallet_rounded,
                                color: const Color(0xFF15803D),
                                bgColor: const Color(0xFFDCFCE7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBentoCard(
                                title: 'Tunggakan Sewa',
                                value: '$overdueCount Kamar',
                                subtitle: overdueCount > 0 ? 'Perlu Ditagih Segera' : 'Semua Lancar',
                                icon: Icons.notification_important_rounded,
                                color: overdueCount > 0 ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                                bgColor: overdueCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Upcoming Due Dates Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tenggat Sewa Penghuni',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
                Text(
                  'Jatuh Tempo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentIndigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Stream Rooms for Upcoming Due Dates of active tenants
            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('rooms').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: accentIndigo));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyDueCard();
                }

                final docs = snapshot.data!.docs;
                List<Room> occupiedRooms = docs
                    .map((doc) => Room.fromFirestore(doc))
                    .where((r) => r.isOccupied && r.nextDueDate != null)
                    .toList();

                if (occupiedRooms.isEmpty) {
                  return _buildEmptyDueCard();
                }

                // Sort by due date (soonest / overdue first)
                occupiedRooms.sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));

                final upcoming = occupiedRooms.take(5).toList();

                return Column(
                  children: upcoming.map((r) => _buildRoomDueRowItem(r)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B254B),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2B3674)),
          ),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFA3AED0)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 44, color: Color(0xFF15803D)),
          const SizedBox(height: 8),
          Text(
            'Tidak ada tagihan jatuh tempo saat ini',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDueRowItem(Room room) {
    final isOverdue = room.isOverdue;
    final daysUntil = room.daysUntilDue;
    final isApproaching = daysUntil != null && daysUntil >= 0 && daysUntil <= 5;

    Color badgeColor = const Color(0xFF15803D);
    Color badgeBg = const Color(0xFFDCFCE7);
    String badgeText = 'Lancar';

    if (isOverdue) {
      badgeColor = const Color(0xFFB91C1C);
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = 'Terlambat';
    } else if (isApproaching) {
      badgeColor = const Color(0xFFB45309);
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = daysUntil == 0 ? 'Hari Ini' : '$daysUntil Hari Lagi';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061B254B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.meeting_room_rounded, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.roomNumber,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF2B3674)),
                  ),
                  Text(
                    room.tenantName.isNotEmpty ? room.tenantName : '(Tanpa Nama)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFA3AED0)),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(room.nextDueDate!),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF2B3674), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
