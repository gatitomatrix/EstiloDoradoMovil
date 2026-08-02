// lib/core/services/geocoding_service.dart
import 'api_service.dart';
import '../config/api_config.dart';

class GeocodingService {
  final ApiService _api = ApiService();

  Future<({double lat, double lon})?> searchAddress(String query) async {
    try {
      final res = await _api.get(
        ApiConfig.geoSearch,
        queryParameters: {'q': query},
      );
      final data = res.data;
      if (data is! List || data.isEmpty) return null;
      final first = data.first;
      if (first is! Map) return null;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;
      return (lat: lat, lon: lon);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>?> reverseAddress(double lat, double lon) async {
    try {
      final res = await _api.get(
        ApiConfig.geoReverse,
        queryParameters: {'lat': lat.toString(), 'lon': lon.toString()},
      );
      if (res.data is! Map) return null;
      final m = Map<String, dynamic>.from(res.data as Map);
      return {
        'via': m['via']?.toString() ?? '',
        'numero': m['numero']?.toString() ?? '',
        'distrito': m['distrito']?.toString() ?? '',
        'provincia': m['provincia']?.toString() ?? '',
        'departamento': m['departamento']?.toString() ?? '',
        'display': m['display']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }
}
