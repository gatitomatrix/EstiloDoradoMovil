// lib/core/config/api_config.dart
class ApiConfig {
  /// Por defecto: API en Render (mismo backend que estilodorado.net.pe).
  /// Local XAMPP: flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://estilo-dorado-api.onrender.com/api',
  );

  /// Clave pública Culqi (sandbox). En prod: --dart-define=CULQI_PK=pk_live_...
  static const String culqiPublicKey = String.fromEnvironment(
    'CULQI_PK',
    defaultValue: 'pk_test_vJYOwLgj0Zghy6SF',
  );

  /// Client ID OAuth tipo Web (el mismo que Angular). Vacío = demo local.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '777778875504-2v87ku2g09ihl0na65ge110hmqm6r2nh.apps.googleusercontent.com',
  );

  static const String whatsappNumber = String.fromEnvironment(
    'WHATSAPP',
    defaultValue: '51916464315',
  );

  // Auth cliente
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String google = '/auth/google';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String updatePassword = '/auth/password';
  static const String checkEmail = '/auth/check-email';
  static const String passwordForgot = '/auth/password/forgot';
  static const String passwordReset = '/auth/password/reset';
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
