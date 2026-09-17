import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Central Share Service for launching dynamic WhatsApp and Email share intent URLs.
class ShareService {
  static Future<void> shareToWhatsApp(BuildContext context, String message, [String mobile = '']) async {
    final cleanPhone = mobile.replaceAll(RegExp(r'\D'), '');
    final encodedMsg = Uri.encodeComponent(message);
    final url = cleanPhone.length >= 10
        ? 'https://wa.me/$cleanPhone?text=$encodedMsg'
        : 'https://api.whatsapp.com/send?text=$encodedMsg';

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp app directly. Message ready for sharing!'),
            backgroundColor: Color(0xFF25D366),
          ),
        );
      }
    }
  }

  static Future<void> shareToEmail(BuildContext context, String recipient, String subject, String body) async {
    final cleanRecipient = recipient.contains('@') ? recipient : '';
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final url = 'mailto:$cleanRecipient?subject=$encodedSubject&body=$encodedBody';

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open mail client directly.'),
            backgroundColor: Color(0xFF0453CD),
          ),
        );
      }
    }
  }
}
