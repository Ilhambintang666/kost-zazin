import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/room.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'Semua'; // 'Semua', 'Lunas', 'Tenggat'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF2B3674);
    const accentIndigo = Color(0xFF4318FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Top Header Summary & Filter Chips
          _buildTopHeader(primaryNavy, accentIndigo),

          // Payment History List Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('payments').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: accentIndigo));
                }

                final docs = snapshot.data?.docs ?? [];
                List<Payment> payments = docs.map((doc) => Payment.fromFirestore(doc)).toList();

                payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

                if (_selectedFilter == 'Lunas') {
                  payments = payments.where((p) => p.status == 'Lunas').toList();
                } else if (_selectedFilter == 'Tenggat') {
                  payments = payments.where((p) => p.status != 'Lunas' || p.isOverdue || p.isApproachingDue).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  payments = payments.where((p) {
                    final roomMatch = p.roomNumber.toLowerCase().contains(_searchQuery.toLowerCase());
                    final tenantMatch = p.tenantName.toLowerCase().contains(_searchQuery.toLowerCase());
                    return roomMatch || tenantMatch;
                  }).toList();
                }

                if (payments.isEmpty) return _buildEmptyState(accentIndigo);

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: payments.length,
                  itemBuilder: (context, index) => _buildPaymentCard(payments[index], primaryNavy, accentIndigo),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPaymentModal(),
        icon: const Icon(Icons.add_card_rounded, size: 22, color: Colors.white),
        label: Text('Catat Bayar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        backgroundColor: accentIndigo,
        elevation: 6,
      ),
    );
  }

  Widget _buildTopHeader(Color primaryNavy, Color accentIndigo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x081B254B), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('payments').snapshots(),
            builder: (context, snapshot) {
              double totalRevenue = 0;
              int overdueCount = 0;

              if (snapshot.hasData) {
                final now = DateTime.now();
                for (var doc in snapshot.data!.docs) {
                  final p = Payment.fromFirestore(doc);
                  if (p.status == 'Lunas' && p.paymentDate.month == now.month && p.paymentDate.year == now.year) {
                    totalRevenue += p.amount;
                  }
                  if (p.isOverdue) overdueCount++;
                }
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildHeaderCard(
                      'Pemasukan Bulan Ini',
                      _formatRupiah(totalRevenue),
                      const Color(0xFF15803D),
                      const Color(0xFFDCFCE7),
                      Icons.account_balance_wallet_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildHeaderCard(
                      'Tunggakan',
                      '$overdueCount Transaksi',
                      const Color(0xFFB91C1C),
                      const Color(0xFFFEE2E2),
                      Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Filled Search
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: primaryNavy),
              decoration: InputDecoration(
                hintText: 'Cari kamar atau penghuni...',
                hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFA3AED0), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA3AED0), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          Row(
            children: ['Semua', 'Lunas', 'Tenggat'].map((label) {
              final isSelected = _selectedFilter == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? accentIndigo : const Color(0xFFF4F7FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        color: isSelected ? Colors.white : const Color(0xFFA3AED0),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(String title, String subtitle, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFFA3AED0)), maxLines: 1),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: color), maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accentIndigo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: accentIndigo),
          const SizedBox(height: 16),
          Text('Belum Ada Riwayat Pembayaran', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment, Color primaryNavy, Color accentIndigo) {
    Color badgeBg = const Color(0xFFDCFCE7);
    Color badgeText = const Color(0xFF15803D);
    String statusLabel = payment.status;

    if (payment.status != 'Lunas') {
      if (payment.isOverdue) {
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFB91C1C);
        statusLabel = 'Terlambat';
      } else if (payment.isApproachingDue) {
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFB45309);
        statusLabel = 'Jatuh Tempo';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x081B254B), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.meeting_room_rounded, color: primaryNavy, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment.roomNumber, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy)),
                        Text(payment.tenantName, style: GoogleFonts.plusJakartaSans(color: const Color(0xFFA3AED0), fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: GoogleFonts.plusJakartaSans(color: badgeText, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 28, color: Color(0xFFF4F7FE)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tgl Bayar: ${_formatDate(payment.paymentDate)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFA3AED0))),
                    Text('Jatuh Tempo: ${_formatDate(payment.nextDueDate)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: badgeText)),
                  ],
                ),
                Text(_formatRupiah(payment.amount), style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold, color: accentIndigo)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmDeletePayment(payment),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text('Hapus', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFEE5D50)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentModal() {
    final formKey = GlobalKey<FormState>();
    String? selectedRoomId;
    Room? selectedRoomObj;
    final amountController = TextEditingController();
    final tenantController = TextEditingController();
    final notesController = TextEditingController();

    DateTime paymentDate = DateTime.now();
    DateTime nextDueDate = DateTime.now().add(const Duration(days: 30));
    String paymentStatus = 'Lunas';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            const primaryNavy = Color(0xFF2B3674);
            const accentIndigo = Color(0xFF4318FF);

            return Padding(
              padding: EdgeInsets.only(top: 20, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(3))),
                      ),
                      const SizedBox(height: 20),
                      Text('Catat Pembayaran Baru', style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.bold, color: primaryNavy)),
                      const SizedBox(height: 20),

                      // Room Dropdown
                      Text('Pilih Kamar', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('rooms').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final rooms = snapshot.data!.docs.map((doc) => Room.fromFirestore(doc)).toList();

                          return Container(
                            decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                            child: DropdownButtonFormField<String>(
                              value: selectedRoomId,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.door_front_door_outlined, color: Color(0xFFA3AED0)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              items: rooms.map((room) {
                                return DropdownMenuItem<String>(
                                  value: room.id,
                                  child: Text('${room.roomNumber} (${room.tenantName.isNotEmpty ? room.tenantName : "Kosong"})'),
                                );
                              }).toList(),
                              onChanged: (roomId) {
                                if (roomId != null) {
                                  final room = rooms.firstWhere((r) => r.id == roomId);
                                  setModalState(() {
                                    selectedRoomId = roomId;
                                    selectedRoomObj = room;
                                    amountController.text = room.price.toInt().toString();
                                    tenantController.text = room.tenantName;
                                  });
                                }
                              },
                              validator: (v) => v == null ? 'Pilih kamar' : null,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tenant Name
                      Text('Nama Penghuni', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                        child: TextFormField(
                          controller: tenantController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                          decoration: InputDecoration(
                            hintText: 'Nama penghuni',
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFA3AED0)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amount
                      Text('Jumlah Bayar (Rp)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                        child: TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                          decoration: InputDecoration(
                            hintText: 'Contoh: 1500000',
                            prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFFA3AED0)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isLoading = true);

                                  try {
                                    await _firestore.collection('payments').add({
                                      'roomId': selectedRoomId ?? '',
                                      'roomNumber': selectedRoomObj?.roomNumber ?? 'Kamar',
                                      'tenantName': tenantController.text.trim(),
                                      'amount': double.parse(amountController.text.trim()),
                                      'paymentDate': Timestamp.fromDate(paymentDate),
                                      'nextDueDate': Timestamp.fromDate(nextDueDate),
                                      'status': paymentStatus,
                                      'notes': notesController.text.trim(),
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    if (mounted) Navigator.pop(context);
                                  } catch (e) {
                                    setModalState(() => isLoading = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('Simpan Pembayaran', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeletePayment(Payment payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus Transaksi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text('Hapus catatan pembayaran ${payment.roomNumber} (${_formatRupiah(payment.amount)})?', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: GoogleFonts.plusJakartaSans())),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore.collection('payments').doc(payment.id).delete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEE5D50)),
            child: Text('Hapus', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
