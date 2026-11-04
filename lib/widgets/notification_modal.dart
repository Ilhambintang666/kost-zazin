import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../models/payment.dart';
import '../utils/whatsapp_helper.dart';

class NotificationModal extends StatefulWidget {
  const NotificationModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationModal(),
    );
  }

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatRupiah(double amount) {
    return WhatsAppHelper.formatRupiah(amount);
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Modal Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: accentIndigo, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pusat Notifikasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryNavy,
                          ),
                        ),
                        Text(
                          'Tagihan pembayaran & riwayat penghuni',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFFA3AED0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFFA3AED0)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: accentIndigo,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFFA3AED0),
                labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Tagihan Pembayaran'),
                  Tab(text: 'Riwayat Penghuni'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tab Bar View Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentNotifications(primaryNavy, accentIndigo),
                _buildTenantHistory(primaryNavy, accentIndigo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentNotifications(Color primaryNavy, Color accentIndigo) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
      builder: (context, roomSnap) {
        if (roomSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = roomSnap.data?.docs ?? [];
        List<Room> occupiedRooms = docs
            .map((d) => Room.fromFirestore(d))
            .where((r) => r.isOccupied && r.nextDueDate != null)
            .toList();

        // Urutkan yang terlambat & jatuh tempo terdekat di atas
        occupiedRooms.sort((a, b) {
          if (a.isOverdue && !b.isOverdue) return -1;
          if (!a.isOverdue && b.isOverdue) return 1;
          return a.nextDueDate!.compareTo(b.nextDueDate!);
        });

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('payments').orderBy('createdAt', descending: true).limit(10).snapshots(),
          builder: (context, paySnap) {
            final payDocs = paySnap.data?.docs ?? [];
            final recentPayments = payDocs.map((d) => Payment.fromFirestore(d)).toList();

            if (occupiedRooms.isEmpty && recentPayments.isEmpty) {
              return _buildEmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'Tidak Ada Notifikasi Pembayaran',
                subtitle: 'Semua tagihan sewa dan pembayaran telah tercatat rapi.',
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                // Bagian Perlu Ditagih
                if (occupiedRooms.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tagihan Jatuh Tempo & Terlambat',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryNavy,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${occupiedRooms.length} Kamar',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFB91C1C),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...occupiedRooms.map((room) => _buildDuePaymentCard(room, primaryNavy, accentIndigo)),
                  const SizedBox(height: 20),
                ],

                // Bagian Transaksi Baru-baru Ini
                if (recentPayments.isNotEmpty) ...[
                  Text(
                    'Riwayat Transaksi Terbaru',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...recentPayments.map((p) => _buildRecentPaymentItem(p, primaryNavy, accentIndigo)),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDuePaymentCard(Room room, Color primaryNavy, Color accentIndigo) {
    final isOverdue = room.isOverdue;
    final daysUntil = room.daysUntilDue;

    Color badgeBg = isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);
    Color badgeColor = isOverdue ? const Color(0xFFB91C1C) : const Color(0xFFB45309);
    String badgeText = isOverdue
        ? 'Terlambat'
        : (daysUntil == 0 ? 'Hari Ini' : '$daysUntil Hari Lagi');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061B254B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.meeting_room_rounded, color: badgeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.roomNumber,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryNavy,
                        ),
                      ),
                      Text(
                        room.tenantName.isNotEmpty ? room.tenantName : '(Tanpa Nama)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFFA3AED0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF4F7FE)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nominal Sewa',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFFA3AED0)),
                  ),
                  Text(
                    _formatRupiah(room.price),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentIndigo,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
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
                icon: const Icon(Icons.chat_rounded, size: 15, color: Colors.white),
                label: Text(
                  'Kirim WA',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPaymentItem(Payment payment, Color primaryNavy, Color accentIndigo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF15803D), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment.roomNumber} - ${payment.tenantName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: primaryNavy,
                  ),
                ),
                Text(
                  'Dibayar: ${_formatDate(payment.paymentDate)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFFA3AED0),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatRupiah(payment.amount),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: const Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantHistory(Color primaryNavy, Color accentIndigo) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        List<Room> occupiedRooms = docs
            .map((d) => Room.fromFirestore(d))
            .where((r) => r.isOccupied)
            .toList();

        // Urutkan penghuni yang paling baru masuk
        occupiedRooms.sort((a, b) {
          if (a.dateOccupied == null) return 1;
          if (b.dateOccupied == null) return -1;
          return b.dateOccupied!.compareTo(a.dateOccupied!);
        });

        if (occupiedRooms.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_off_rounded,
            title: 'Belum Ada Penghuni Masuk',
            subtitle: 'Data penghuni yang terdaftar di kamar akan ditampilkan di sini.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          itemCount: occupiedRooms.length,
          itemBuilder: (context, index) {
            final room = occupiedRooms[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x061B254B),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.person_rounded, color: accentIndigo, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              room.tenantName.isNotEmpty ? room.tenantName : '(Tanpa Nama)',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: primaryNavy,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                room.roomNumber,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.login_rounded, size: 14, color: Color(0xFF15803D)),
                            const SizedBox(width: 4),
                            Text(
                              'Masuk: ${room.dateOccupied != null ? _formatDate(room.dateOccupied!) : '-'}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF15803D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (room.tenantPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 14, color: Color(0xFFA3AED0)),
                              const SizedBox(width: 4),
                              Text(
                                room.tenantPhone,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFFA3AED0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (room.tenantPhone.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        WhatsAppHelper.sendRentBill(
                          context: context,
                          phone: room.tenantPhone,
                          tenantName: room.tenantName,
                          roomNumber: room.roomNumber,
                          amount: room.price,
                          dueDate: room.nextDueDate,
                        );
                      },
                      icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 22),
                      tooltip: 'Hubungi via WhatsApp',
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F7FE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: const Color(0xFFA3AED0)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2B3674),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFFA3AED0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

