import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../widgets/custom_fab_location.dart';

class KamarScreen extends StatefulWidget {
  const KamarScreen({super.key});

  @override
  State<KamarScreen> createState() => _KamarScreenState();
}

class _KamarScreenState extends State<KamarScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'Semua';
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
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
    final fabBottomOffset = (bottomPadding > 0 ? bottomPadding + 8 : 16) + 66 + 14;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildTopHeader(primaryNavy, accentIndigo),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('rooms').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: accentIndigo));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Terjadi kesalahan saat memuat data: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFFEE5D50)),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                List<Room> rooms = docs.map((doc) => Room.fromFirestore(doc)).toList();

                rooms.sort((a, b) {
                  if (a.isOverdue && !b.isOverdue) return -1;
                  if (!a.isOverdue && b.isOverdue) return 1;
                  return a.roomNumber.compareTo(b.roomNumber);
                });

                if (_selectedFilter == 'Tersedia') {
                  rooms = rooms.where((r) => r.status == 'Tersedia').toList();
                } else if (_selectedFilter == 'Terisi') {
                  rooms = rooms.where((r) => r.status == 'Terisi').toList();
                }

                if (_searchQuery.isNotEmpty) {
                  rooms = rooms.where((r) {
                    final matchNum = r.roomNumber.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchTenant = r.tenantName.toLowerCase().contains(_searchQuery.toLowerCase());
                    return matchNum || matchTenant;
                  }).toList();
                }

                if (rooms.isEmpty) return _buildEmptyState(accentIndigo);

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 165),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) => _buildRoomCard(rooms[index], primaryNavy, accentIndigo),
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
              onPressed: () => _showAddOrEditRoomModal(),
              icon: const Icon(Icons.add_home_rounded, size: 22, color: Colors.white),
              label: Text(
                'Tambah Kamar',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('rooms').snapshots(),
            builder: (context, snapshot) {
              int total = snapshot.data?.docs.length ?? 0;
              int tersedia = 0, terisi = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final status = (doc.data() as Map<String, dynamic>)['status'];
                  if (status == 'Tersedia') tersedia++;
                  if (status == 'Terisi') terisi++;
                }
              }
              return Row(
                children: [
                  Expanded(child: _buildMetricBadge('Total', '$total', Icons.meeting_room_rounded, primaryNavy, const Color(0xFFF4F7FE))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricBadge('Tersedia', '$tersedia', Icons.check_circle_rounded, const Color(0xFF15803D), const Color(0xFFDCFCE7))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricBadge('Terisi', '$terisi', Icons.person_rounded, const Color(0xFFB45309), const Color(0xFFFEF3C7))),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Filled Search Field
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: primaryNavy),
              decoration: InputDecoration(
                hintText: 'Cari nomor kamar atau nama penghuni...',
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
            children: ['Semua', 'Tersedia', 'Terisi'].map((label) {
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
          )
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String label, String count, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFFA3AED0))),
              Text(count, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
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
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.meeting_room_outlined, size: 56, color: accentIndigo),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Data Kamar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2B3674),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Klik tombol "Tambah Kamar" di bawah untuk menambahkan kamar pertama Anda.',
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

  Widget _buildRoomCard(Room room, Color primaryNavy, Color accentIndigo) {
    final isOccupied = room.isOccupied;

    Color badgeBg = const Color(0xFFDCFCE7);
    Color badgeText = const Color(0xFF15803D);
    String statusLabel = 'Tersedia';

    if (isOccupied) {
      if (room.isOverdue) {
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFB91C1C);
        statusLabel = 'Terlambat Bayar';
      } else {
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFB45309);
        statusLabel = 'Terisi';
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
                      decoration: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text(room.roomNumber, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold, color: primaryNavy)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: GoogleFonts.plusJakartaSans(color: badgeText, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    Text('Harga Sewa / Bulan', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFA3AED0))),
                    Text(_formatRupiah(room.price), style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: accentIndigo)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Penghuni', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFA3AED0))),
                    Text(isOccupied ? room.tenantName : '(Kosong)', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: isOccupied ? FontWeight.bold : FontWeight.w400, color: primaryNavy)),
                  ],
                ),
              ],
            ),
            if (isOccupied && room.dateOccupied != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: room.isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFF4F7FE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 22, color: room.isOverdue ? const Color(0xFFB91C1C) : accentIndigo),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Masuk: ${_formatDate(room.dateOccupied)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFA3AED0))),
                          Text('Jatuh Tempo: ${_formatDate(room.nextDueDate)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: room.isOverdue ? const Color(0xFFB91C1C) : primaryNavy)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quick Action: Isi Penghuni jika kamar kosong, atau Check-out jika terisi
                if (!isOccupied)
                  TextButton.icon(
                    onPressed: () => _showAddOrEditRoomModal(room: room, forceOccupiedMode: true),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: Text('+ Isi Penghuni', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF15803D),
                      backgroundColor: const Color(0xFFDCFCE7),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _confirmCheckoutTenant(room),
                    icon: const Icon(Icons.person_remove_rounded, size: 16),
                    label: Text('Check-out', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB45309),
                      backgroundColor: const Color(0xFFFEF3C7),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAddOrEditRoomModal(room: room),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text('Edit', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: accentIndigo),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteRoom(room),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: Text('Hapus', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFEE5D50)),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- DYNAMIC FORM MODAL BOTTOM SHEET WITH STATEFULBUILDER ---
  void _showAddOrEditRoomModal({Room? room, bool forceOccupiedMode = false}) {
    final isEditing = room != null;
    final formKey = GlobalKey<FormState>();

    final roomNumberController = TextEditingController(text: isEditing ? room.roomNumber : '');
    final priceController = TextEditingController(text: isEditing && room.price > 0 ? room.price.toInt().toString() : '');
    final tenantNameController = TextEditingController(text: isEditing ? room.tenantName : '');
    final descriptionController = TextEditingController(text: isEditing ? room.description : '');

    String selectedStatus = forceOccupiedMode
        ? 'Terisi'
        : (isEditing ? room.status : 'Tersedia');

    DateTime? dateOccupied = (forceOccupiedMode && (room?.dateOccupied == null))
        ? DateTime.now()
        : (isEditing ? room.dateOccupied : null);

    DateTime? nextDueDate = (forceOccupiedMode && (room?.nextDueDate == null))
        ? Room.calculateNextDueDate(DateTime.now())
        : (isEditing ? room.nextDueDate : null);

    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            const accentIndigo = Color(0xFF4318FF);
            const primaryNavy = Color(0xFF2B3674);

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
                        child: Container(
                          width: 44, height: 5,
                          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isEditing
                            ? (forceOccupiedMode ? 'Tambah Penghuni Kamar' : 'Edit Data Kamar')
                            : 'Tambah Kamar Baru',
                        style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.bold, color: primaryNavy),
                      ),
                      const SizedBox(height: 20),

                      // Room Number
                      Text('Nomor / Nama Kamar', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                        child: TextFormField(
                          controller: roomNumberController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Kamar 101 atau A-01',
                            prefixIcon: Icon(Icons.meeting_room_outlined, color: Color(0xFFA3AED0)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price
                      Text('Harga Sewa Per Bulan (Rp)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                        child: TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                          decoration: const InputDecoration(
                            hintText: 'Contoh: 1500000',
                            prefixIcon: Icon(Icons.payments_outlined, color: Color(0xFFA3AED0)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                            final sanitized = v.replaceAll('.', '').replaceAll(',', '').trim();
                            if (double.tryParse(sanitized) == null) return 'Masukkan angka yang valid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Dropdown
                      Text('Status Kamar', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.info_outline_rounded, color: Color(0xFFA3AED0)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Tersedia', child: Text('Tersedia (Kosong)')),
                            DropdownMenuItem(value: 'Terisi', child: Text('Terisi (Ada Penghuni)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedStatus = val;
                                if (selectedStatus == 'Terisi') {
                                  dateOccupied ??= DateTime.now();
                                  nextDueDate = Room.calculateNextDueDate(dateOccupied!);
                                } else {
                                  dateOccupied = null;
                                  nextDueDate = null;
                                  tenantNameController.clear();
                                }
                              });
                            }
                          },
                        ),
                      ),

                      // DYNAMIC EXPANSION WITH AnimatedSize
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: selectedStatus == 'Terisi'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  Text('Nama Penghuni', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                                    child: TextFormField(
                                      controller: tenantNameController,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                                      decoration: const InputDecoration(
                                        hintText: 'Masukkan nama penghuni',
                                        prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFFA3AED0)),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      validator: (v) => selectedStatus == 'Terisi' && (v == null || v.trim().isEmpty) ? 'Wajib diisi jika Terisi' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Tanggal Ditempati', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: dateOccupied ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          dateOccupied = picked;
                                          nextDueDate = Room.calculateNextDueDate(picked);
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.event_available_rounded, color: Color(0xFFA3AED0)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              dateOccupied != null ? _formatDate(dateOccupied) : 'Pilih Tanggal Ditempati',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryNavy),
                                            ),
                                          ),
                                          const Icon(Icons.calendar_month_rounded, size: 20, color: accentIndigo),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (nextDueDate != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFC7D2FE)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.auto_awesome_rounded, color: accentIndigo, size: 22),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Tanggal Jatuh Tempo Otomatis:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF4338CA))),
                                                Text('${_formatDate(nextDueDate)} (1 Bulan)', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: accentIndigo)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      Text('Fasilitas / Catatan', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: primaryNavy)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF4F7FE), borderRadius: BorderRadius.circular(16)),
                        child: TextFormField(
                          controller: descriptionController,
                          maxLines: 2,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryNavy),
                          decoration: const InputDecoration(
                            hintText: 'Contoh: AC, Kamar Mandi Dalam, Kasur',
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
                                  setModalState(() => isLoading = true);

                                  try {
                                    final sanitizedPrice = double.parse(
                                      priceController.text.replaceAll('.', '').replaceAll(',', '').trim(),
                                    );

                                    final roomData = {
                                      'room_number': roomNumberController.text.trim(),
                                      'price': sanitizedPrice,
                                      'status': selectedStatus,
                                      'tenant_name': selectedStatus == 'Terisi' ? tenantNameController.text.trim() : '',
                                      'date_occupied': selectedStatus == 'Terisi' && dateOccupied != null ? Timestamp.fromDate(dateOccupied!) : null,
                                      'next_due_date': selectedStatus == 'Terisi' && nextDueDate != null ? Timestamp.fromDate(nextDueDate!) : null,
                                      'description': descriptionController.text.trim(),
                                      'updated_at': FieldValue.serverTimestamp(),
                                    };

                                    if (isEditing) {
                                      await _firestore.collection('rooms').doc(room.id).update(roomData);
                                    } else {
                                      roomData['created_at'] = FieldValue.serverTimestamp();
                                      await _firestore.collection('rooms').add(roomData);
                                    }

                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEditing ? 'Data kamar berhasil diperbarui!' : 'Kamar baru berhasil ditambahkan!',
                                            style: GoogleFonts.plusJakartaSans(),
                                          ),
                                          backgroundColor: const Color(0xFF059669),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setModalState(() => isLoading = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal menyimpan: $e', style: GoogleFonts.plusJakartaSans()),
                                          backgroundColor: const Color(0xFFEE5D50),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
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
                                  isEditing ? 'Simpan Perubahan' : 'Tambah Kamar Baru',
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

  void _confirmCheckoutTenant(Room room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Check-out Penghuni', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          'Kosongkan ${room.roomNumber} dari penghuni "${room.tenantName}"?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestore.collection('rooms').doc(room.id).update({
                  'status': 'Tersedia',
                  'tenant_name': '',
                  'date_occupied': null,
                  'next_due_date': null,
                  'updated_at': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Penghuni berhasil di-checkout. Status kamar sekarang Tersedia.', style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: const Color(0xFF059669),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal check-out: $e', style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: const Color(0xFFEE5D50),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB45309),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Ya, Check-out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRoom(Room room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus Kamar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus ${room.roomNumber}? Data kamar ini akan dihapus permanen.', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: GoogleFonts.plusJakartaSans())),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestore.collection('rooms').doc(room.id).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kamar ${room.roomNumber} berhasil dihapus.', style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: const Color(0xFFEE5D50),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e', style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: const Color(0xFFEE5D50),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEE5D50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
