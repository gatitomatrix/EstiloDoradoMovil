import '../config/api_config.dart';

class Celular {
  /// WhatsApp de la tienda. Solo para el botón de ayuda, no para bloquear el checkout.
  static String get tienda {
    var d = ApiConfig.whatsappNumber.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('51') && d.length >= 11) d = d.substring(2);
    if (d.length > 9) d = d.substring(0, 9);
    return RegExp(r'^9\d{8}$').hasMatch(d) ? d : '916464315';
  }

  /// 9 dígitos que empiezan en 9, o vacío.
  /// El celular de la tienda también es válido: el dueño puede comprar con ese número.
  static String cliente(String? raw) {
    var d = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('51') && d.length >= 11) d = d.substring(2);
    if (d.length > 9) d = d.substring(0, 9);
    if (!RegExp(r'^9\d{8}$').hasMatch(d)) return '';
    return d;
  }

  /// "pagado" → "Pagado", "tarjeta" → "Tarjeta".
  static String etiqueta(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }
}
