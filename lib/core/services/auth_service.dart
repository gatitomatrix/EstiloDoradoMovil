// lib/core/services/auth_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String errorMessage(Object e) {
    if (e is DioException) {
      final err = e.error;
      if (err is ApiException) return err.message;
      final data = e.response?.data;
      if (data is Map) {
        final m = data['message'];
        if (m is String && m.isNotEmpty) return m;
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'No se pudo conectar al servidor. Revisa que Laravel esté en marcha.';
      }
      return e.message ?? 'Error de red';
    }
    return e.toString();
  }

  Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String password,
    String? apellido,
    String? telefono,
    String? direccion,
  }) async {
    try {
      final response = await _api.post(ApiConfig.register, {
        'nombre': nombre,
        'apellido': apellido ?? '',
        'telefono': telefono ?? '',
        'direccion': direccion ?? '',
        'email': email,
        'password': password,
        'password_confirmation': password,
      });
      return await _persistSession(response.data);
    } catch (e) {
      debugPrint('Error en register: $e');
      return {'success': false, 'error': errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post(ApiConfig.login, {
        'email': email,
        'password': password,
      });
      return await _persistSession(response.data);
    } catch (e) {
      debugPrint('Error en login: $e');
      return {'success': false, 'error': errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>?> me() async {
    try {
      final response = await _api.get(ApiConfig.me);
      final user = Map<String, dynamic>.from(response.data as Map);
      await _storage.write(key: 'user', value: jsonEncode(user));
      return user;
    } catch (e) {
      debugPrint('Error en me: $e');
      return null;
    }
  }

  Future<bool> logout() async {
    try {
      await _api.post(ApiConfig.logout, {});
    } catch (_) {
      // aunque falle la red, limpiamos local
    }
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user');
    return true;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    final raw = await _storage.read(key: 'user');
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _persistSession(dynamic data) async {
    if (data is! Map) {
      return {'success': false, 'error': 'Respuesta inválida del servidor'};
    }

    // A veces viene anidado
    final map = Map<String, dynamic>.from(data);
    final token = map['token']?.toString();
    final user = map['cliente'] ?? map['user'];

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'error': map['message']?.toString() ?? 'No se recibió token de sesión',
      };
    }

    await _storage.write(key: 'auth_token', value: token);
    if (user != null) {
      await _storage.write(key: 'user', value: jsonEncode(user));
    }

    return {
      'success': true,
      'user': user is Map ? Map<String, dynamic>.from(user) : user,
      'token': token,
    };
  }

  Future<Map<String, dynamic>?> updateProfile({
    required String nombre,
    String? apellido,
    String? telefono,
    String? direccion,
  }) async {
    try {
      final response = await _api.put(ApiConfig.me, {
        'nombre': nombre,
        'apellido': apellido ?? '',
        'telefono': telefono ?? '',
        'direccion': direccion ?? '',
      });

      final user = Map<String, dynamic>.from(response.data as Map);
      await _storage.write(key: 'user', value: jsonEncode(user));
      return user;
    } catch (e) {
      debugPrint('Error en updateProfile: $e');
      return null;
    }
  }

  Future<bool> checkEmail(String email) async {
    try {
      final response = await _api.post(ApiConfig.checkEmail, {
        'email': email.trim(),
      });
      // 200 = existe
      return response.statusCode == 200;
    } catch (e) {
      // 404 u otro error = no existe / fallo
      debugPrint('Error checkEmail: $e');
      if (e is DioException && e.response?.statusCode == 404) {
        return false;
      }
      // Si el API no responde, no fingir "no existe"
      rethrow;
    }
  }

  /// Laravel espera: email + contrasena (no password)
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await _api.post(ApiConfig.resetSimple, {
        'email': email.trim(),
        'contrasena': newPassword,
      });

      return {
        'success': true,
        'message': response.data is Map
            ? (response.data['message']?.toString() ?? 'Contraseña actualizada')
            : 'Contraseña actualizada',
      };
    } catch (e) {
      debugPrint('Error resetPassword: $e');
      return {
        'success': false,
        'error': errorMessage(e),
      };
    }
  }
}
