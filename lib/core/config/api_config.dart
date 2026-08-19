// lib/core/config/api_config.dart
class ApiConfig {
  /// Emulador Android: http://10.0.2.2:8000/api
  /// iOS simulador:   http://127.0.0.1:8000/api
  /// Celular físico:  http://IP_DE_TU_PC:8000/api
  /// flutter run --dart-define=API_BASE=http://192.168.1.42:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  /// Clave pública Culqi (sandbox). En prod: --dart-define=CULQI_PK=pk_live_...
  static const String culqiPublicKey = String.fromEnvironment(
    'CULQI_PK',
    defaultValue: 'pk_test_tu_clave_publica',
  );

  /// Client ID OAuth tipo Web (el mismo que Angular). Vacío = demo local.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // Auth cliente
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String google = '/auth/google';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String updatePassword = '/auth/password';
  static const String checkEmail = '/auth/check-email';
  static const String resetSimple = '/auth/password/reset-simple';

  // Tienda
  static const String productos = '/productos';
  static const String categorias = '/categorias';

  /// Chatbot / asistente IA (Ollama o Gemini vía Laravel)
  static const String asistente = '/asistente';

  // Geo
  static const String geoSearch = '/geo/search';
  static const String geoReverse = '/geo/reverse';

  // Pedidos / checkout (alineado con Angular)
  static const String confirmarPedido = '/pedidos/confirmar';
  static const String misPedidos = '/pedidos';
  static const String pedidosMios = '/pedidos/mios';
  static const String pedidoById = '/pedidos'; // + /{id}
  static const String pagarCulqi = '/pagar-con-culqi';
}
