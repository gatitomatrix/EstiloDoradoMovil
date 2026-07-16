// lib/core/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

// ==================== EXCEPCIONES PERSONALIZADAS ====================
class ApiException extends DioException {
  final String? customMessage;

  ApiException({
    required super.requestOptions,
    super.error,
    super.response,
    this.customMessage,
  }) : super(
          type: DioExceptionType.badResponse,
          message: customMessage ?? error?.toString() ?? response?.statusMessage,
        );

  @override
  String toString() => 'ApiException: $message (Status: ${response?.statusCode})';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({
    required super.requestOptions,
    super.error,
    super.response,
  }) : super(customMessage: 'No autorizado o sesión expirada');
}

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  final _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;

          // Manejo de token expirado (401)
          if (statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                final opts = error.requestOptions;
                final token = await _storage.read(key: 'auth_token');
                opts.headers['Authorization'] = 'Bearer $token';
                final response = await _dio.fetch(opts);
                handler.resolve(response);
                return;
              }
            } catch (_) {
              await _storage.delete(key: 'auth_token');
            } finally {
              _isRefreshing = false;
            }
          }

          // Rechazamos con excepciones personalizadas (ahora compatibles)
          if (statusCode == 401) {
            handler.reject(UnauthorizedException(
              requestOptions: error.requestOptions,
              error: error.error,
              response: error.response,
            ));
          } else {
            handler.reject(ApiException(
              requestOptions: error.requestOptions,
              error: error.error,
              response: error.response,
            ));
          }
        },
      ),
    );
  }

  // ==================== REFRESH TOKEN ====================
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200) {
        final newToken = response.data['token'];
        await _storage.write(key: 'auth_token', value: newToken);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ==================== MÉTODOS BÁSICOS ====================
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, dynamic data) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, dynamic data) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, dynamic data) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  // ==================== MULTIPART ====================
  Future<Response> postMultipart(
    String path, {
    required Map<String, dynamic> data,
    Map<String, MultipartFile>? files,
  }) async {
    final formData = FormData.fromMap(data);
    files?.forEach((key, file) {
      formData.files.add(MapEntry(key, file));
    });
    return _dio.post(path, data: formData, options: Options(contentType: 'multipart/form-data'));
  }

  // ==================== DESCARGAR ARCHIVOS ====================
  Future<void> downloadFile({
    required String urlPath,
    required String savePath,
    Function(int, int)? onProgress,
  }) async {
    await _dio.download(urlPath, savePath, onReceiveProgress: onProgress);
  }
}