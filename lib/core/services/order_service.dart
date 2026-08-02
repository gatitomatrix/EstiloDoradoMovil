// lib/core/services/order_service.dart
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/checkout_models.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _api = ApiService();

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
    return ConfirmarRes.fromJson(Map<String, dynamic>.from(res.data as Map));
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

  /// Cobra con Culqi vía backend (token de tarjeta)
  Future<bool> pagarConCulqi({
    required String token,
    required double monto,
    required String correo,
    String descripcion = 'Compra Estilo Dorado',
  }) async {
    try {
      final res = await _api.post(ApiConfig.pagarCulqi, {
        'token': token,
        'monto': monto,
        'descripcion': descripcion,
        'correo': correo,
      });
      final data = res.data;
      if (data is Map && data['success'] == true) return true;
      return false;
    } catch (e) {
      debugPrint('pagarConCulqi error: $e');
      return false;
    }
  }
}
