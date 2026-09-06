import '../config/api_config.dart';

String? resolvePublicUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final u = url.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
  final origin = base.replaceFirst(RegExp(r'/api$'), '');
  if (u.startsWith('/')) return '$origin$u';
  return '$base/$u';
}
