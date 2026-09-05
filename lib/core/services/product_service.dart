// lib/core/services/product_service.dart
import '../config/api_config.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _api = ApiService();

  Future<List<Product>> getAllProducts({String? search}) async {
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
}
