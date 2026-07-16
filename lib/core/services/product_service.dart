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
        queryParameters: search != null ? {'q': search} : null,
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error cargando productos: $e');
      rethrow;
    }
  }
}