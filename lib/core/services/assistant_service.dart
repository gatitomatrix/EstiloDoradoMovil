// lib/core/services/assistant_service.dart
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AssistantAction {
  final String type;
  final int? id;
  final int qty;
  final String? nombre;
  final double? precio;
  final int? stock;
  final String? imagenUrl;

  AssistantAction({
    required this.type,
    this.id,
    this.qty = 1,
    this.nombre,
    this.precio,
    this.stock,
    this.imagenUrl,
  });

  factory AssistantAction.fromJson(Map<String, dynamic> json) {
    return AssistantAction(
      type: (json['type'] ?? '').toString(),
      id: int.tryParse(json['id']?.toString() ?? ''),
      qty: int.tryParse(json['qty']?.toString() ?? '1') ?? 1,
      nombre: json['nombre']?.toString(),
      precio: double.tryParse(json['precio']?.toString() ?? ''),
      stock: int.tryParse(json['stock']?.toString() ?? ''),
      imagenUrl: json['imagen_url']?.toString(),
    );
  }
}

class AssistantReply {
  final String reply;
  final String driver;
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic>? pedido;
  final List<String> suggestions;
  final AssistantAction? action;

  AssistantReply({
    required this.reply,
    required this.driver,
    required this.products,
    this.pedido,
    required this.suggestions,
    this.action,
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
    AssistantAction? action;
    if (json['action'] is Map) {
      action = AssistantAction.fromJson(Map<String, dynamic>.from(json['action'] as Map));
    }
    return AssistantReply(
      reply: (json['reply'] ?? '').toString(),
      driver: (json['driver'] ?? 'rules').toString(),
      products: products,
      pedido: pedido,
      suggestions: suggestions,
      action: action,
    );
  }
}

class AssistantService {
  final ApiService _api = ApiService();

  Future<AssistantReply> send(String message, {List<int> offeredIds = const []}) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        if (offeredIds.isNotEmpty) 'offered_ids': offeredIds,
      };
      final response = await _api.postWithTimeout(
        ApiConfig.asistente,
        data: body,
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
