import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/room.dart';
import '../utils/whatsapp_helper.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatRupiah(double amount) {
    try {
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp .', decimalDigits: 0);
      return formatter.format(amount);
    } catch (_) {
      return 'Rp .${amount.toInt()}';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('rooms').snapshots(),
        builder: (context, roomSnap) {
          if (roomSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentIndigo));
          }

          if (roomSnap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFFA3AED0)),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Periksa koneksi internet Anda dan coba lagi.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFFA3AED0)),
                    ),
                  ],
                ),
              ),
            );
          }

          // Hitung semua statistik kamar dari satu stream
          int totalRooms = 0;
          int occupiedRooms = 0;
          int availableRooms = 0;
          int overdueCount = 0;
          List<Room> upcomingDueRooms = [];

          if (roomSnap.hasData) {
            totalRooms = roomSnap.data!.docs.length;
            for (var doc in roomSnap.data!.docs) {
              final r = Room.fromFirestore(doc);
              if (r.isOccupied) {
                occupiedRooms++;
                if (r.isOverdue) overdueCount++;
                if (r.nextDueDate != null) upcomingDueRooms.add(r);
              } else {
                availableRooms++;
              }
            }
          }

          // Urutkan berdasarkan jatuh tempo terdekat
          upcomingDueRooms.sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
          final upcoming = upcomingDueRooms.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                // Bento Grid - Nested payment stream hanya untuk revenue
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('payments').snapshots(),
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
                ),
                const SizedBox(height: 24),

                // Tenggat Sewa Section Title
                Text(
                  'Tenggat Sewa Penghuni',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
                const SizedBox(height: 14),

                // Daftar Jatuh Tempo (dari stream rooms yang sama)
                if (upcoming.isEmpty) _buildEmptyDueCard(),
                ...upcoming.map((r) => _buildRoomDueRowItem(r)),
              ],
            ),
          );
        },
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
          Expanded(
            child: Row(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.roomNumber,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF2B3674)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        room.tenantName.isNotEmpty ? room.tenantName : '(Tanpa Nama)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFA3AED0)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(width: 8),
              // Tombol WhatsApp Cepat
              IconButton(
                onPressed: () {
                  WhatsAppHelper.sendRentBill(
                    context: context,
                    phone: room.tenantPhone,
                    tenantName: room.tenantName,
                    roomNumber: room.roomNumber,
                    amount: room.price,
                    dueDate: room.nextDueDate,
                    status: isOverdue ? 'Terlambat Bayar' : 'Jatuh Tempo',
                  );
                },
                icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 22),
                tooltip: 'Ingatkan Tagihan via WhatsApp',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0FDF4),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
