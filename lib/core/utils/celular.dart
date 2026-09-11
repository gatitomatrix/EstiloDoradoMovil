import '../config/api_config.dart';

class Celular {
  /// WhatsApp de la tienda. No se usa como celular del cliente.
  static String get tienda {
    var d = ApiConfig.whatsappNumber.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('51') && d.length >= 11) d = d.substring(2);
    if (d.length > 9) d = d.substring(0, 9);
    return RegExp(r'^9\d{8}$').hasMatch(d) ? d : '916464315';
  }

  /// 9 dígitos que empiezan en 9, o vacío. Descarta el de la tienda.
  static String cliente(String? raw) {
    var d = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('51') && d.length >= 11) d = d.substring(2);
    if (d.length > 9) d = d.substring(0, 9);
    if (!RegExp(r'^9\d{8}$').hasMatch(d)) return '';
    if (d == tienda) return '';
    return d;
  }
}
