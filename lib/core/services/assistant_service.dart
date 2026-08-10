// lib/core/services/assistant_service.dart
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AssistantReply {
  final String reply;
  final String driver;
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic>? pedido;
  final List<String> suggestions;

  AssistantReply({
    required this.reply,
    required this.driver,
    required this.products,
    this.pedido,
    required this.suggestions,
  });

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    final products = <Map<String, dynamic>>[];
    final raw = json['products'];
    if (raw is List) {
      for (final p in raw) {
        if (p is Map) products.add(Map<String, dynamic>.from(p));
      }
    }
    final suggestions = <String>[];
    final s = json['suggestions'];
    if (s is List) {
      for (final x in s) {
        suggestions.add(x.toString());
      }
    }
    Map<String, dynamic>? pedido;
    if (json['pedido'] is Map) {
      pedido = Map<String, dynamic>.from(json['pedido'] as Map);
    }
    return AssistantReply(
      reply: (json['reply'] ?? '').toString(),
      driver: (json['driver'] ?? 'rules').toString(),
      products: products,
      pedido: pedido,
      suggestions: suggestions,
    );
  }
}

class AssistantService {
  final ApiService _api = ApiService();

  Future<AssistantReply> send(String message) async {
    try {
      final response = await _api.postWithTimeout(
        ApiConfig.asistente,
        data: {'message': message},
        receiveTimeout: const Duration(seconds: 120),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AssistantReply.fromJson(data);
      }
      if (data is Map) {
        return AssistantReply.fromJson(Map<String, dynamic>.from(data));
      }
      throw ApiException(message: 'Respuesta inválida del asistente');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      final msg = e.type == DioExceptionType.receiveTimeout
          ? 'El asistente tardó demasiado. ¿Ollama está corriendo en tu PC?'
          : (e.message ?? 'Error de red con el asistente');
      throw ApiException(message: msg, statusCode: e.response?.statusCode);
    }
  }
}
