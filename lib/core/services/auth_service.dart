// lib/core/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    try {
      final response = await _dio.post(ApiConfig.register, data: {
        'nombre': nombre,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      final token = response.data['token'] ?? response.data['access_token'];
      final user = response.data['cliente'] ?? response.data['user'];

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user', value: user.toString());

      return {'success': true, 'user': user};
    } catch (e) {
      debugPrint('Error en register: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(ApiConfig.login, data: {
        'email': email,
        'password': password,
      });

      final token = response.data['token'] ?? response.data['access_token'];
      final user = response.data['cliente'] ?? response.data['user'];

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user', value: user.toString());

      return {'success': true, 'user': user};
    } catch (e) {
      debugPrint('Error en login: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}