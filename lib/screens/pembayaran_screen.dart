import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/room.dart';
import '../widgets/custom_fab_location.dart';
import '../utils/currency_formatter.dart';
import '../utils/whatsapp_helper.dart';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF2B3674);
    const accentIndigo = Color(0xFF4318FF);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double fabBottomOffset = (bottomPadding > 0 ? bottomPadding + 8.0 : 16.0) + 80.0;

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

                if (snapshot.hasError) {
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Periksa koneksi internet Anda dan coba lagi.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFFA3AED0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 165),
                  itemCount: payments.length,
                  itemBuilder: (context, index) => _buildPaymentCard(payments[index], primaryNavy, accentIndigo),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingAboveBarFabLocation(
        bottomOffset: fabBottomOffset,
        rightOffset: 20.0,
      ),
      floatingActionButton: isKeyboardOpen
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddOrEditPaymentModal(),
              icon: const Icon(Icons.add_card_rounded, size: 22, color: Colors.white),
              label: Text(
                'Catat Pembayaran',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              backgroundColor: accentIndigo,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

          // Search with Clear Button
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
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFA3AED0)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
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
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined, size: 56, color: accentIndigo),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Riwayat Pembayaran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2B3674),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Klik tombol di bawah untuk mencatat transaksi sewa kamar pertama.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFFA3AED0),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddOrEditPaymentModal(),
              icon: const Icon(Icons.add_card_rounded, size: 18),
              label: Text(
                'Catat Pembayaran Pertama',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
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
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
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
            if (payment.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Catatan: ${payment.notes}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol WhatsApp untuk konfirmasi bayar / info
                TextButton.icon(
                  onPressed: () async {
                    String phone = '';
                    if (payment.roomId.isNotEmpty) {
                      try {
                        final roomDoc = await _firestore.collection('rooms').doc(payment.roomId).get();
                        if (roomDoc.exists) {
                          phone = roomDoc.data()?['tenant_phone'] ?? '';
                        }
                      } catch (_) {}
                    }

                    if (mounted) {
                      WhatsAppHelper.sendRentBill(
                        context: context,
                        phone: phone,
                        tenantName: payment.tenantName,
                        roomNumber: payment.roomNumber,
                        amount: payment.amount,
                        dueDate: payment.nextDueDate,
                        status: payment.status,
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_rounded, size: 15, color: Color(0xFF25D366)),
                  label: Text(
                    'Kirim WA',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF0FDF4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAddOrEditPaymentModal(payment: payment),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text('Edit', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: accentIndigo,
                        backgroundColor: const Color(0xFFEEF2FF),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _confirmDeletePayment(payment),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      style: IconButton.styleFrom(foregroundColor: const Color(0xFFEE5D50)),
                      tooltip: 'Hapus Transaksi',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditPaymentModal({Payment? payment}) {
    final isEditing = payment != null;
    final formKey = GlobalKey<FormState>();

    String? selectedRoomId = isEditing ? payment.roomId : null;
    String selectedRoomNumber = isEditing ? payment.roomNumber : '';
    final amountController = TextEditingController(
      text: isEditing ? CurrencyInputFormatter.formatNumber(payment.amount) : '',
    );
    final tenantController = TextEditingController(text: isEditing ? payment.tenantName : '');
    final notesController = TextEditingController(text: isEditing ? payment.notes : '');

    DateTime paymentDate = isEditing ? payment.paymentDate : DateTime.now();
    DateTime nextDueDate = isEditing ? payment.nextDueDate : DateTime.now().add(const Duration(days: 30));
    String paymentStatus = isEditing ? payment.status : 'Lunas';
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
                      Text(
                        isEditing ? 'Edit Catatan Pembayaran' : 'Catat Pembayaran Baru',
                        style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.bold, color: primaryNavy),
                      ),
                      const SizedBox(height: 20),

                      // Room Dropdown
                      Text('Pilih Kamar', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('rooms').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
                          }
                          final rooms = snapshot.data!.docs.map((doc) => Room.fromFirestore(doc)).toList();

                          // Validasi agar selectedRoomId ada di daftar kamar
                          final validRoomId = rooms.any((r) => r.id == selectedRoomId) ? selectedRoomId : null;

                          return Container(
                            decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                            child: DropdownButtonFormField<String>(
                              initialValue: validRoomId,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.meeting_room_outlined, color: Color(0xFFA3AED0)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              hint: Text('Pilih kamar kos', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFA3AED0), fontSize: 14)),
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
                                    selectedRoomNumber = room.roomNumber;
                                    if (room.price > 0 && amountController.text.isEmpty) {
                                      amountController.text = CurrencyInputFormatter.formatNumber(room.price);
                                    }
                                    if (tenantController.text.isEmpty) {
                                      tenantController.text = room.tenantName;
                                    }
                                    if (!isEditing && room.nextDueDate != null) {
                                      nextDueDate = room.nextDueDate!;
                                    }
                                  });
                                }
                              },
                              validator: (v) => v == null && selectedRoomId == null ? 'Silakan pilih kamar' : null,
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
                          decoration: const InputDecoration(
                            hintText: 'Nama penghuni',
                            prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFFA3AED0)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Nama penghuni wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amount with CurrencyInputFormatter
                      Text('Jumlah Bayar (Rp .700.000)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                        child: TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFFA3AED0)),
                            prefixText: 'Rp .',
                            prefixStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy),
                            hintText: '700.000',
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFA3AED0), fontSize: 14, fontWeight: FontWeight.normal),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Jumlah bayar wajib diisi';
                            final sanitized = CurrencyInputFormatter.parse(v);
                            if (sanitized <= 0) return 'Masukkan nominal yang valid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Pembayaran Dropdown
                      Text('Status Pembayaran', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                        child: DropdownButtonFormField<String>(
                          initialValue: paymentStatus,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.check_circle_outline_rounded, color: Color(0xFFA3AED0)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                            DropdownMenuItem(value: 'Belum Lunas', child: Text('Belum Lunas')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => paymentStatus = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment Date Picker
                      Text('Tanggal Pembayaran', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: paymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setModalState(() => paymentDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFFA3AED0)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_formatDate(paymentDate), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy)),
                              ),
                              const Icon(Icons.edit_calendar_rounded, size: 20, color: accentIndigo),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Next Due Date Picker
                      Text('Jatuh Tempo Berikutnya', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: nextDueDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setModalState(() => nextDueDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              const Icon(Icons.event_repeat_rounded, size: 20, color: Color(0xFFA3AED0)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_formatDate(nextDueDate), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy)),
                              ),
                              const Icon(Icons.edit_calendar_rounded, size: 20, color: accentIndigo),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes / Catatan
                      Text('Catatan / Keterangan (Opsional)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                        child: TextFormField(
                          controller: notesController,
                          maxLines: 2,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Transfer BCA an. Budi, Lunas 1 bulan',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
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
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);
                                  setModalState(() => isLoading = true);

                                  try {
                                    final sanitizedAmount = CurrencyInputFormatter.parse(amountController.text);

                                    final paymentData = {
                                      'roomId': selectedRoomId ?? '',
                                      'roomNumber': selectedRoomNumber.isNotEmpty ? selectedRoomNumber : 'Kamar',
                                      'tenantName': tenantController.text.trim(),
                                      'amount': sanitizedAmount,
                                      'paymentDate': Timestamp.fromDate(paymentDate),
                                      'nextDueDate': Timestamp.fromDate(nextDueDate),
                                      'status': paymentStatus,
                                      'notes': notesController.text.trim(),
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    };

                                    if (isEditing) {
                                      await _firestore.collection('payments').doc(payment.id).update(paymentData);
                                    } else {
                                      paymentData['createdAt'] = FieldValue.serverTimestamp();
                                      await _firestore.collection('payments').add(paymentData);
                                    }

                                    // Jika status Lunas dan ada kamar terpilih, perbarui next_due_date kamar
                                    if (paymentStatus == 'Lunas' && selectedRoomId != null && selectedRoomId!.isNotEmpty) {
                                      await _firestore.collection('rooms').doc(selectedRoomId).update({
                                        'next_due_date': Timestamp.fromDate(nextDueDate),
                                        'updated_at': FieldValue.serverTimestamp(),
                                      });
                                    }

                                    navigator.pop();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEditing ? 'Pembayaran berhasil diperbarui!' : 'Pembayaran berhasil dicatat!',
                                          style: GoogleFonts.plusJakartaSans(),
                                        ),
                                        backgroundColor: const Color(0xFF059669),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (e) {
                                    setModalState(() => isLoading = false);
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menyimpan data. Silakan coba lagi.', style: GoogleFonts.plusJakartaSans()),
                                        backgroundColor: const Color(0xFFEE5D50),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  isEditing ? 'Simpan Perubahan' : 'Simpan Pembayaran',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
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
              try {
                await _firestore.collection('payments').doc(payment.id).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Catatan pembayaran berhasil dihapus.', style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: const Color(0xFFEE5D50),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus data. Silakan coba lagi.', style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: const Color(0xFFEE5D50),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEE5D50)),
            child: Text('Hapus', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
