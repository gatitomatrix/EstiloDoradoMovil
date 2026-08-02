// lib/core/services/order_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/checkout_models.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _api = ApiService();

  static String errorMessage(Object e) {
    if (e is DioException) {
      final err = e.error;
      if (err is ApiException) return err.message;
      final data = e.response?.data;
      if (data is Map) {
        final m = data['message'] ?? data['error'];
        if (m != null) return m.toString();
        // Validación Laravel
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      }
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'El servidor tardó demasiado (emisión SUNAT). Revisa Mis compras: el pedido pudo crearse.';
      }
      return e.message ?? 'Error de red';
    }
    return e.toString();
  }

  /// POST /pedidos/confirmar — mismo contrato que Angular OrderService
  Future<ConfirmarRes> confirmar({
    required String formaPago, // tarjeta | yape | efectivo
    String? culqiId,
    String? direccionEntrega,
    required List<ConfirmarItem> items,
    String? comprobante, // FA | BO
    InvoiceData? factura,
    BoletaData? boleta,
  }) async {
    final body = <String, dynamic>{
      'forma_pago': formaPago,
      'direccion_entrega': direccionEntrega,
      'items': items.map((e) => e.toJson()).toList(),
    };
    if (formaPago != 'efectivo') {
      body['culqi_id'] = culqiId;
      if (comprobante != null) body['comprobante'] = comprobante;
      if (factura != null) body['factura'] = factura.toJson();
      if (boleta != null) body['boleta'] = boleta.toJson();
    }

    // SUNAT puede tardar; timeout más alto solo en confirmar
    final res = await _api.post(
      ApiConfig.confirmarPedido,
      body,
      receiveTimeout: const Duration(seconds: 90),
    );
    final data = res.data;
    if (data is! Map) {
      throw ApiException(message: 'Respuesta inválida del servidor al confirmar');
    }
    final map = Map<String, dynamic>.from(data);
    // Algunos wrappers devuelven { pedido: {...} }
    if (map['pedido'] is Map) {
      return ConfirmarRes.fromJson(Map<String, dynamic>.from(map['pedido'] as Map));
    }
    final parsed = ConfirmarRes.fromJson(map);
    if (parsed.idPedido <= 0) {
      throw ApiException(
        message: map['message']?.toString() ?? 'No se obtuvo el id del pedido',
      );
    }
    return parsed;
  }

  Future<ConfirmarRes> getById(int id) async {
    final res = await _api.get('${ApiConfig.pedidoById}/$id');
    final data = res.data;
    if (data is Map && data['pedido'] is Map) {
      return ConfirmarRes.fromJson(Map<String, dynamic>.from(data['pedido'] as Map));
    }
    return ConfirmarRes.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<PedidoListItem>> listMine() async {
    try {
      final res = await _api.get(ApiConfig.misPedidos);
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => PedidoListItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('listMine error: $e');
      rethrow;
    }
  }

  Future<ConfirmarRes> cancelar(int id, {String? motivo}) async {
    final res = await _api.post('${ApiConfig.pedidoById}/$id/cancelar', {
      if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
    });
    final data = res.data;
    if (data is Map && data['pedido'] is Map) {
      return ConfirmarRes.fromJson(Map<String, dynamic>.from(data['pedido'] as Map));
    }
    return ConfirmarRes.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<ConfirmarRes> pagarPendiente({
    required int id,
    required String formaPago,
    required String culqiId,
    required String comprobante,
    InvoiceData? factura,
    BoletaData? boleta,
  }) async {
    final body = <String, dynamic>{
      'forma_pago': formaPago,
      'culqi_id': culqiId,
      'comprobante': comprobante,
    };
    if (factura != null) body['factura'] = factura.toJson();
    if (boleta != null) body['boleta'] = boleta.toJson();

    final res = await _api.post(
      '${ApiConfig.pedidoById}/$id/pagar',
      body,
      receiveTimeout: const Duration(seconds: 90),
    );
    final data = res.data;
    if (data is Map && data['pedido'] is Map) {
      return ConfirmarRes.fromJson(Map<String, dynamic>.from(data['pedido'] as Map));
    }
    return ConfirmarRes.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
