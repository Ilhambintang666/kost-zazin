import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static String normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('8')) {
      cleaned = '62$cleaned';
    }
    return cleaned;
  }

  static String formatRupiah(double amount) {
    try {
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      return formatter.format(amount);
    } catch (_) {
      return 'Rp ${amount.toInt()}';
    }
  }

  static String formatDate(DateTime date) {
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Mengirim pesan pengingat tagihan sewa kos via WhatsApp
  static Future<void> sendRentBill({
    required BuildContext context,
    required String phone,
    required String tenantName,
    required String roomNumber,
    required double amount,
    DateTime? dueDate,
    String? status,
  }) async {
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor HP penghuni belum diisi. Silakan edit data kamar terlebih dahulu.'),
          backgroundColor: Color(0xFFEE5D50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final normalizedPhone = normalizePhoneNumber(phone);
    final formattedAmount = formatRupiah(amount);
    final formattedDueDate = dueDate != null ? formatDate(dueDate) : 'Segera';

    final message = '''
Halo Kak *$tenantName*, 
Salam dari manajemen KostKu 🙏

Berikut kami sampaikan rincian tagihan sewa kamar kos Anda:
🏠 *Kamar:* $roomNumber
💰 *Nominal:* $formattedAmount
📅 *Jatuh Tempo:* $formattedDueDate
📌 *Status:* ${status ?? 'Belum Lunas'}

Mohon kesediaannya untuk melakukan pembayaran tepat waktu. Jika sudah melakukan pembayaran, mohon konfirmasi dan kirimkan bukti transfer ya Kak.

Terima kasih atas kerja samanya! ✨
'''.trim();

    final encodedMessage = Uri.encodeComponent(message);
    final urlString = 'https://wa.me/$normalizedPhone?text=$encodedMessage';
    final uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka WhatsApp. Pastikan aplikasi WhatsApp terpasang di perangkat.'),
              backgroundColor: Color(0xFFEE5D50),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka WhatsApp: $e'),
            backgroundColor: const Color(0xFFEE5D50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

