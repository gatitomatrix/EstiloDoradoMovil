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

    final res = await _api.post(ApiConfig.confirmarPedido, body);
    return ConfirmarRes.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<ConfirmarRes> getById(int id) async {
    final res = await _api.get('${ApiConfig.pedidoById}/$id');
    final data = res.data;
    if (data is Map && data['pedido'] is Map) {
      return ConfirmarRes.fromJson(Map<String, dynamic>.from(data['pedido'] as Map));
    }
    return ConfirmarRes.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// GET /pedidos — lista enriquecida (producto_label, friendly…)
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

  /// POST /pedidos/{id}/cancelar — solo si estado = pendiente
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

  /// POST /pedidos/{id}/pagar — completa pago de pedido pendiente (yape/tarjeta)
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

    final res = await _api.post('${ApiConfig.pedidoById}/$id/pagar', body);
    final data = res.data;
    if (data is Map && data['pedido'] is Map) {
      return ConfirmarRes.fromJson(Map<String, dynamic>.from(data['pedido'] as Map));
    }
    return ConfirmarRes.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
