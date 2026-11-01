import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String roomId;
  final String roomNumber;
  final String tenantName;
  final double amount;
  final DateTime paymentDate;
  final DateTime nextDueDate;
  final String status; // 'Lunas', 'Belum Lunas', 'Terlambat'
  final String notes;
  final DateTime? createdAt;

  Payment({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.tenantName,
    required this.amount,
    required this.paymentDate,
    required this.nextDueDate,
    required this.status,
    this.notes = '',
    this.createdAt,
  });

  bool get isOverdue {
    if (status == 'Lunas') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.isBefore(today);
  }

  bool get isApproachingDue {
    if (status == 'Lunas') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    final difference = due.difference(today).inDays;
    return difference >= 0 && difference <= 5;
  }

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return Payment(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      tenantName: data['tenantName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentDate: data['paymentDate'] != null
          ? (data['paymentDate'] as Timestamp).toDate()
          : DateTime.now(),
      nextDueDate: data['nextDueDate'] != null
          ? (data['nextDueDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      status: data['status'] ?? 'Lunas',
      notes: data['notes'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomNumber': roomNumber,
      'tenantName': tenantName,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'status': status,
      'notes': notes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
