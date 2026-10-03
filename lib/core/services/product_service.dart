// lib/core/services/product_service.dart
import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _api = ApiService();

  Future<List<Product>> getAllProducts({String? search}) async {
    try {
      return await _readProducts(search);
    } catch (e) {
      if (!_puedeReintentar(e)) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return _readProducts(search);
    }
  }

  bool _puedeReintentar(Object e) {
    if (e is! DioException) return true;
    final code = e.response?.statusCode;
    if (code != null && code < 500) return false;
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError ||
        (code != null && code >= 500);
  }

  Future<List<Product>> _readProducts(String? search) async {
    final response = await _api.get(
      ApiConfig.productos,
      queryParameters: search != null && search.isNotEmpty ? {'q': search} : null,
    );

    final raw = response.data;
    List list = const [];
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final inner = raw['data'] ?? raw['productos'] ?? raw['items'];
      if (inner is List) list = inner;
    }

    final out = <Product>[];
    for (final item in list) {
      if (item is Map) {
        try {
          out.add(Product.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
    }
    return out;
  }

  Future<Product?> getById(int id) async {
    try {
      final response = await _api.get('${ApiConfig.productos}/$id');
      final data = response.data is Map && response.data['data'] != null
          ? response.data['data']
          : response.data;
      if (data is Map) {
        return Product.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    final all = await getAllProducts();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<({bool activa, String texto, double porcentaje})> getPromoActiva() async {
    try {
      final response = await _api.get(ApiConfig.promocionActiva);
      final data = response.data;
      if (data is Map) {
        return (
          activa: data['activa'] == true,
          texto: (data['texto'] ?? '').toString().trim(),
          porcentaje: (data['porcentaje'] as num?)?.toDouble() ?? 0,
        );
      }
    } catch (_) {}
    return (activa: false, texto: '', porcentaje: 0.0);
  }
}
