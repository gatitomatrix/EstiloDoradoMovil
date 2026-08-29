import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class Whatsapp {
  static String get number {
    var n = ApiConfig.whatsappNumber.replaceAll(RegExp(r'\D'), '');
    if (n.length == 9 && n.startsWith('9')) n = '51$n';
    return n;
  }

  static bool get enabled => number.length >= 11;

  static Uri uri([String? text]) {
    final q = (text != null && text.trim().isNotEmpty)
        ? '?text=${Uri.encodeComponent(text.trim())}'
        : '';
    return Uri.parse('https://wa.me/$number$q');
  }

  static Future<bool> open([String? text]) async {
    if (!enabled) return false;
    return launchUrl(uri(text), mode: LaunchMode.externalApplication);
  }
}
