// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.42:8000/api';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Productos
  static const String productos = '/productos';

  // Pedidos
  static const String pedidos = '/pedidos';
  static const String misPedidos = '/pedidos/mis-pedidos';
}