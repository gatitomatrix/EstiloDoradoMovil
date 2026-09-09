// lib/core/services/geocoding_service.dart
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class GeocodingService {
  final ApiService _api = ApiService();
  final Dio _osm = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {'Accept': 'application/json'},
  ));

  Future<({double lat, double lon})?> searchAddress(
    String query, {
    double? lat,
    double? lon,
  }) async {
    try {
      final qp = <String, dynamic>{'q': query};
      if (lat != null && lon != null) {
        qp['lat'] = lat.toString();
        qp['lon'] = lon.toString();
      }
      final res = await _api.get(
        ApiConfig.geoSearch,
        queryParameters: qp,
      );
      final data = res.data;
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map) {
          final la = double.tryParse(first['lat']?.toString() ?? '');
          final lo = double.tryParse(first['lon']?.toString() ?? '');
          if (la != null && lo != null) return (lat: la, lon: lo);
        }
      }
    } catch (_) {}
    return _searchNominatim(query);
  }

  Future<Map<String, String>?> reverseAddress(double lat, double lon) async {
    try {
      final res = await _api.get(
        ApiConfig.geoReverse,
        queryParameters: {'lat': lat.toString(), 'lon': lon.toString()},
      );
      if (res.data is Map) {
        final mapped = _mapHit(Map<String, dynamic>.from(res.data as Map));
        if (_usable(mapped)) return mapped;
      }
    } catch (_) {}
    return _reverseNominatim(lat, lon) ?? await _reversePhoton(lat, lon);
  }

  bool _usable(Map<String, String>? r) {
    if (r == null) return false;
    final via = (r['via'] ?? '').trim();
    final display = (r['display'] ?? '').trim();
    if (RegExp(r'^ubicaci[oó]n\s+-?\d', caseSensitive: false).hasMatch(display)) {
      return false;
    }
    return via.length > 1 || (display.length > 3 && !RegExp(r'^-?\d').hasMatch(display));
  }

  Map<String, String> _mapHit(Map<String, dynamic> m) => {
        'via': m['via']?.toString() ?? '',
        'numero': m['numero']?.toString() ?? '',
        'distrito': m['distrito']?.toString() ?? '',
        'provincia': m['provincia']?.toString() ?? '',
        'departamento': m['departamento']?.toString() ?? '',
        'display': m['display']?.toString() ?? '',
      };

  Future<({double lat, double lon})?> _searchNominatim(String query) async {
    try {
      final res = await _osm.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'format': 'json',
          'limit': 1,
          'addressdetails': 1,
          'countrycodes': 'pe',
          'q': query,
        },
      );
      final data = res.data;
      if (data is List && data.isNotEmpty) {
        final la = double.tryParse(data.first['lat']?.toString() ?? '');
        final lo = double.tryParse(data.first['lon']?.toString() ?? '');
        if (la != null && lo != null) return (lat: la, lon: lo);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, String>?> _reverseNominatim(double lat, double lon) async {
    try {
      final res = await _osm.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'addressdetails': 1,
          'zoom': 18,
          'accept-language': 'es',
          'lat': lat,
          'lon': lon,
        },
      );
      final j = res.data;
      if (j is! Map) return null;
      final a = j['address'] is Map ? Map<String, dynamic>.from(j['address'] as Map) : <String, dynamic>{};
      final via = (a['road'] ?? a['pedestrian'] ?? a['residential'] ?? a['footway'] ?? j['name'] ?? '').toString().trim();
      final numero = (a['house_number'] ?? '').toString().trim();
      final display = (j['display_name'] ?? '').toString().trim();
      final hit = {
        'via': via,
        'numero': numero,
        'distrito': (a['city_district'] ?? a['suburb'] ?? a['town'] ?? a['village'] ?? a['city'] ?? '').toString(),
        'provincia': (a['province'] ?? a['county'] ?? a['city'] ?? '').toString(),
        'departamento': (a['state'] ?? a['region'] ?? '').toString(),
        'display': display,
      };
      return _usable(hit) ? hit : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>?> _reversePhoton(double lat, double lon) async {
    try {
      final res = await _osm.get(
        'https://photon.komoot.io/reverse',
        queryParameters: {'lat': lat, 'lon': lon, 'lang': 'en'},
      );
      final feats = res.data is Map ? (res.data['features'] as List?) : null;
      if (feats == null || feats.isEmpty) return null;
      final p = (feats.first as Map)['properties'];
      if (p is! Map) return null;
      final via = (p['street'] ?? p['name'] ?? '').toString().trim();
      final numero = (p['housenumber'] ?? '').toString().trim();
      final display = [
        '$via $numero'.trim(),
        p['district'],
        p['city'],
        p['state'],
      ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
      final hit = {
        'via': via,
        'numero': numero,
        'distrito': (p['district'] ?? p['locality'] ?? p['city'] ?? '').toString(),
        'provincia': (p['city'] ?? p['county'] ?? '').toString(),
        'departamento': (p['state'] ?? '').toString(),
        'display': display,
      };
      return _usable(hit) ? hit : null;
    } catch (_) {
      return null;
    }
  }
}
