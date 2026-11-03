import 'dart:typed_data';

import 'package:app_movil_estilo_dorado/core/config/api_config.dart';
import 'package:app_movil_estilo_dorado/core/services/api_service.dart';
import 'package:app_movil_estilo_dorado/core/services/geocoding_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _ApiStub extends ApiService {
  Object? data;
  bool unavailable = false;
  String? requestedPath;
  Map<String, dynamic>? requestedQuery;

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    requestedPath = path;
    requestedQuery = queryParameters;
    final options = RequestOptions(path: path);
    if (unavailable) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return Response(requestOptions: options, data: data, statusCode: 200);
  }
}

class _ProviderAdapter implements HttpClientAdapter {
  final List<String> calls = [];
  final String nominatimBody;
  final String photonBody;

  _ProviderAdapter({
    this.nominatimBody = '{}',
    this.photonBody = '{"features":[]}',
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.uri.host);
    return ResponseBody.fromString(
      options.uri.host.contains('nominatim') ? nominatimBody : photonBody,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _ApiStub api;

  setUp(() => api = _ApiStub());

  GeocodingService serviceWith(_ProviderAdapter adapter) {
    final osm = Dio()..httpClientAdapter = adapter;
    return GeocodingService(api: api, osm: osm);
  }

  test('search uses backend coordinates and sends the map bias', () async {
    api.data = [
      {'lat': '-10.66848', 'lon': '-76.25688'},
    ];
    final adapter = _ProviderAdapter();
    final result = await serviceWith(
      adapter,
    ).searchAddress('Pasco', lat: -10.6, lon: -76.2);

    expect(result, (lat: -10.66848, lon: -76.25688));
    expect(api.requestedPath, ApiConfig.geoSearch);
    expect(api.requestedQuery, {'q': 'Pasco', 'lat': '-10.6', 'lon': '-76.2'});
    expect(adapter.calls, isEmpty);
  });

  test('search falls back when the backend is unavailable', () async {
    api.unavailable = true;
    final adapter = _ProviderAdapter(
      nominatimBody: '[{"lat":"-10.66848","lon":"-76.25688"}]',
    );

    final result = await serviceWith(adapter).searchAddress('Pasco');

    expect(result, (lat: -10.66848, lon: -76.25688));
    expect(adapter.calls, ['nominatim.openstreetmap.org']);
  });

  test(
    'reverse uses the backend address for the selected coordinates',
    () async {
      api.data = {
        'via': 'Jirón Lima',
        'numero': '123',
        'display': 'Jirón Lima 123',
      };
      final adapter = _ProviderAdapter();

      final result = await serviceWith(
        adapter,
      ).reverseAddress(-10.66848, -76.25688);

      expect(result?['via'], 'Jirón Lima');
      expect(result?['numero'], '123');
      expect(api.requestedPath, ApiConfig.geoReverse);
      expect(api.requestedQuery, {'lat': '-10.66848', 'lon': '-76.25688'});
      expect(adapter.calls, isEmpty);
    },
  );

  test(
    'reverse reaches Photon after Nominatim returns no usable address',
    () async {
      api.unavailable = true;
      final adapter = _ProviderAdapter(
        photonBody:
            '{"features":[{"properties":{"street":"Jirón Lima","housenumber":"123","city":"Pasco","state":"Pasco"}}]}',
      );

      final result = await serviceWith(
        adapter,
      ).reverseAddress(-10.66848, -76.25688);

      expect(result?['via'], 'Jirón Lima');
      expect(result?['numero'], '123');
      expect(adapter.calls, [
        'nominatim.openstreetmap.org',
        'photon.komoot.io',
      ]);
    },
  );

  test(
    'reverse does not call Photon if Nominatim resolves the address',
    () async {
      api.data = {'display': 'Ubicación -10.66848, -76.25688'};
      final adapter = _ProviderAdapter(
        nominatimBody:
            '{"address":{"road":"Jirón Lima","house_number":"123"},"display_name":"Jirón Lima 123, Pasco"}',
      );

      final result = await serviceWith(
        adapter,
      ).reverseAddress(-10.66848, -76.25688);

      expect(result?['via'], 'Jirón Lima');
      expect(adapter.calls, ['nominatim.openstreetmap.org']);
    },
  );

  test('reverse returns null if no provider can resolve the point', () async {
    api.data = {};
    final adapter = _ProviderAdapter();

    expect(
      await serviceWith(adapter).reverseAddress(-10.66848, -76.25688),
      isNull,
    );
    expect(adapter.calls, ['nominatim.openstreetmap.org', 'photon.komoot.io']);
  });
}
