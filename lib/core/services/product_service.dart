// lib/core/services/product_service.dart
import '../../../core/config/api_config.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';

class ProductService {
  final ApiService _api = ApiService();

  Future<List<Product>> getAllProducts({String? search}) async {
    try {
      final response = await _api.get(
        ApiConfig.productos,
        queryParameters: search != null && search.isNotEmpty ? {'q': search} : null,
      );

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] as List? ?? []);
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error cargando productos: $e');
      rethrow;
    }
  }

  Future<Product?> getById(int id) async {
    try {
      final response = await _api.get('${ApiConfig.productos}/$id');
      final data = response.data is Map && response.data['data'] != null
          ? response.data['data']
          : response.data;
      return Product.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      // Fallback: buscar en listado
      final all = await getAllProducts();
      try {
        return all.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
  }
}
