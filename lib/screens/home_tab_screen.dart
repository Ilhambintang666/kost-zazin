import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                          const SizedBox(height: 4),
                          Text(
                            'Kelola operasional KostKu hari ini',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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

                if (roomSnap.hasData) {
                  totalRooms = roomSnap.data!.docs.length;
                  for (var doc in roomSnap.data!.docs) {
                    final status = (doc.data() as Map<String, dynamic>)['status'] ?? 'Tersedia';
                    if (status == 'Terisi') {
                      occupiedRooms++;
                    } else {
                      availableRooms++;
                    }
                  }
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('payments').snapshots(),
                  builder: (context, paySnap) {
                    double monthlyRevenue = 0;
                    int overdueCount = 0;
                    final now = DateTime.now();

                    if (paySnap.hasData) {
                      for (var doc in paySnap.data!.docs) {
                        final p = Payment.fromFirestore(doc);
                        if (p.status == 'Lunas' &&
                            p.paymentDate.month == now.month &&
                            p.paymentDate.year == now.year) {
                          monthlyRevenue += p.amount;
                        }
                        if (p.isOverdue) overdueCount++;
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
                                subtitle: 'Kapasitas',
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
                                subtitle: '$availableRooms Kosong',
                                icon: Icons.person_pin_rounded,
                                color: const Color(0xFFB45309),
                                bgColor: const Color(0xFFFEF3C7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12, height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBentoCard(
                                title: 'Pendapatan Bulan Ini',
                                value: _formatRupiah(monthlyRevenue),
                                subtitle: 'Total Lunas',
                                icon: Icons.account_balance_wallet_rounded,
                                color: const Color(0xFF15803D),
                                bgColor: const Color(0xFFDCFCE7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBentoCard(
                                title: 'Tunggakan Sewa',
                                value: '$overdueCount Transaksi',
                                subtitle: 'Perlu Ditagih',
                                icon: Icons.notification_important_rounded,
                                color: const Color(0xFFB91C1C),
                                bgColor: const Color(0xFFFEE2E2),
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
                  'Tenggat Waktu Mendatang',
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

            // Stream Payments for Due Dates
            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('payments').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: accentIndigo));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyDueCard();
                }

                final docs = snapshot.data!.docs;
                List<Payment> payments = docs.map((doc) => Payment.fromFirestore(doc)).toList();
                payments.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

                final upcoming = payments.take(5).toList();

                return Column(
                  children: upcoming.map((p) => _buildDueRowItem(p)).toList(),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 44, color: Color(0xFF15803D)),
          const SizedBox(height: 8),
          Text(
            'Tidak ada tagihan jatuh tempo saat ini',
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDueRowItem(Payment payment) {
    final isOverdue = payment.isOverdue;
    final isApproaching = payment.isApproachingDue;

    Color badgeColor = const Color(0xFF15803D);
    Color badgeBg = const Color(0xFFDCFCE7);
    String badgeText = 'Aman';

    if (isOverdue) {
      badgeColor = const Color(0xFFB91C1C);
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = 'Terlambat';
    } else if (isApproaching) {
      badgeColor = const Color(0xFFB45309);
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = 'Jatuh Tempo';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                    payment.roomNumber,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF2B3674)),
                  ),
                  Text(
                    payment.tenantName,
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
                _formatDate(payment.nextDueDate),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF2B3674), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
