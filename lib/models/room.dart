import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String roomNumber;
  final double price;
  final String status; // 'Tersedia' or 'Terisi'
  final String tenantName;
  final DateTime? dateOccupied; // Tanggal Ditempati
  final DateTime? nextDueDate;  // Tanggal Jatuh Tempo (Auto Calculated)
  final String description;
  final DateTime? createdAt;

  Room({
    required this.id,
    required this.roomNumber,
    required this.price,
    required this.status,
    this.tenantName = '',
    this.dateOccupied,
    this.nextDueDate,
    this.description = '',
    this.createdAt,
  });

  bool get isOccupied => status.toLowerCase() == 'terisi';

  // Helper untuk mengecek apakah sewa sudah lewat jatuh tempo
  bool get isOverdue {
    if (!isOccupied || nextDueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate!.year, nextDueDate!.month, nextDueDate!.day);
    return due.isBefore(today);
  }

  // Helper sisa hari menuju jatuh tempo
  int? get daysUntilDue {
    if (!isOccupied || nextDueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate!.year, nextDueDate!.month, nextDueDate!.day);
    return due.difference(today).inDays;
  }

  // Smart Helper: Menghitung Tanggal Jatuh Tempo 1 bulan ke depan dari tanggal ditempati
  static DateTime calculateNextDueDate(DateTime dateOccupied) {
    int year = dateOccupied.year;
    int month = dateOccupied.month + 1;
    if (month > 12) {
      month = 1;
      year++;
    }
    int day = dateOccupied.day;
    int daysInNextMonth = DateTime(year, month + 1, 0).day;
    if (day > daysInNextMonth) {
      day = daysInNextMonth;
    }
    return DateTime(year, month, day);
  }

  factory Room.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return Room(
      id: doc.id,
      roomNumber: data['room_number'] ?? data['roomNumber'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      status: data['status'] ?? 'Tersedia',
      tenantName: data['tenant_name'] ?? data['tenantName'] ?? '',
      dateOccupied: data['date_occupied'] != null
          ? (data['date_occupied'] as Timestamp).toDate()
          : (data['dateOccupied'] != null
              ? (data['dateOccupied'] as Timestamp).toDate()
              : null),
      nextDueDate: data['next_due_date'] != null
          ? (data['next_due_date'] as Timestamp).toDate()
          : (data['nextDueDate'] != null
              ? (data['nextDueDate'] as Timestamp).toDate()
              : null),
      description: data['description'] ?? '',
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : (data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'room_number': roomNumber,
      'price': price,
      'status': status,
      'tenant_name': tenantName,
      'date_occupied': dateOccupied != null ? Timestamp.fromDate(dateOccupied!) : null,
      'next_due_date': nextDueDate != null ? Timestamp.fromDate(nextDueDate!) : null,
      'description': description,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  Room copyWith({
    String? id,
    String? roomNumber,
    double? price,
    String? status,
    String? tenantName,
    DateTime? dateOccupied,
    DateTime? nextDueDate,
    String? description,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      price: price ?? this.price,
      status: status ?? this.status,
      tenantName: tenantName ?? this.tenantName,
      dateOccupied: dateOccupied ?? this.dateOccupied,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Room && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
