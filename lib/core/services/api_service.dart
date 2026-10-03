// lib/core/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({String message = 'No autorizado o sesión expirada'})
      : super(message: message, statusCode: 401);
}

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _storage
                .read(key: 'auth_token')
                .timeout(const Duration(seconds: 3));
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;

          if (status == 401) {
            try {
              await _storage.delete(key: 'auth_token').timeout(const Duration(seconds: 3));
              await _storage.delete(key: 'user').timeout(const Duration(seconds: 3));
            } catch (_) {}
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: DioExceptionType.badResponse,
                error: UnauthorizedException(),
              ),
            );
            return;
          }

          final data = error.response?.data;
          String message = error.message ?? 'Error de red';
          if (data is Map) {
            message = (data['message'] ?? data['error'] ?? message).toString();
          }

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: ApiException(
                message: message,
                statusCode: status,
                data: data,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(
    String path, [
    dynamic data,
  ]) =>
      _dio.post(path, data: data);

  /// POST con timeout de recepción personalizado (p. ej. confirmar + SUNAT).
  Future<Response> postWithTimeout(
    String path, {
    dynamic data,
    Duration receiveTimeout = const Duration(seconds: 90),
  }) =>
      _dio.post(
        path,
        data: data,
        options: Options(receiveTimeout: receiveTimeout),
      );

  Future<Response> put(String path, [dynamic data]) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}
