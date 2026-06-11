import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Opens WhatsApp with a pre-filled maintenance reminder message.
  /// If the target phone number is provided, opens chat with that number.
  /// Otherwise opens WhatsApp with message ready to send to anyone.
  static Future<void> sendMaintenanceReminder({
    required String vehicleName,
    required String maintenanceType,
    required String remainingInfo,
    String? phoneNumber,
  }) async {
    final message = '🔧 *Pengingat Perawatan*\n\n'
        'Kendaraan: $vehicleName\n'
        'Perawatan: $maintenanceType\n'
        'Status: $remainingInfo\n\n'
        'Dikirim dari OtoBuzz';

    await _openWhatsApp(message: message, phoneNumber: phoneNumber);
  }

  /// Sends a fleet summary via WhatsApp
  static Future<void> sendFleetSummary({
    required int totalVehicles,
    required int overdueCount,
    required List<String> urgentItems,
    String? phoneNumber,
  }) async {
    final urgentList = urgentItems.isNotEmpty
        ? urgentItems.map((item) => '• $item').join('\n')
        : '• Tidak ada';

    final message = '📊 *Ringkasan Armada OtoBuzz*\n\n'
        'Total kendaraan: $totalVehicles\n'
        'Perawatan terlambat: $overdueCount\n\n'
        '*Perlu segera:*\n'
        '$urgentList\n\n'
        'Dikirim dari OtoBuzz';

    await _openWhatsApp(message: message, phoneNumber: phoneNumber);
  }

  /// Check if WhatsApp is installed
  static Future<bool> isWhatsAppInstalled() async {
    final whatsappUri = Uri.parse('whatsapp://send?text=test');
    return await canLaunchUrl(whatsappUri);
  }

  /// Opens WhatsApp with the given message and optional phone number
  static Future<void> _openWhatsApp({
    required String message,
    String? phoneNumber,
  }) async {
    final encodedMessage = Uri.encodeComponent(message);

    Uri uri;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Format phone number: remove leading 0, add country code if needed
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '62${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('+') &&
          !formattedPhone.startsWith('62')) {
        formattedPhone = '62$formattedPhone';
      }
      formattedPhone = formattedPhone.replaceAll('+', '');
      uri = Uri.parse('https://wa.me/$formattedPhone?text=$encodedMessage');
    } else {
      uri = Uri.parse('whatsapp://send?text=$encodedMessage');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Try fallback with https://wa.me
      final fallbackUri =
          Uri.parse('https://wa.me/?text=$encodedMessage');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
