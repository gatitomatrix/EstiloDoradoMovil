// lib/core/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  String? _nextRouteAfterLogin;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  String? get nextRouteAfterLogin => _nextRouteAfterLogin;

  /// Verifica si hay sesión al arrancar la app
  Future<void> checkAuth() async {
    _isLoggedIn = await _authService.isLoggedIn();

    if (_isLoggedIn) {
      _user = await _authService.getStoredUser();

      // Valida el token con el backend
      final me = await _authService.me();
      if (me != null) {
        _user = me;
      } else {
        _isLoggedIn = false;
        _user = null;
      }
    }

    notifyListeners();
  }

  Future<bool> register(
    String nombre,
    String email,
    String password, {
    String? apellido,
    String? telefono,
    String? direccion,
  }) async {
    final response = await _authService.register(
      nombre: nombre,
      email: email,
      password: password,
      apellido: apellido,
      telefono: telefono,
      direccion: direccion,
    );

    if (response['success'] == true) {
      _isLoggedIn = true;
      _user = response['user'] is Map
          ? Map<String, dynamic>.from(response['user'] as Map)
          : null;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    final response = await _authService.login(email, password);

    if (response['success'] == true) {
      _isLoggedIn = true;
      _user = response['user'] is Map
          ? Map<String, dynamic>.from(response['user'] as Map)
          : null;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _user = null;
    _nextRouteAfterLogin = null;
    notifyListeners();
  }

  void setNextRouteAfterLogin(String route) {
    _nextRouteAfterLogin = route;
    notifyListeners();
  }

  void clearNextRouteAfterLogin() {
    _nextRouteAfterLogin = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String nombre,
    String? apellido,
    String? telefono,
    String? direccion,
  }) async {
    final user = await _authService.updateProfile(
      nombre: nombre,
      apellido: apellido,
      telefono: telefono,
      direccion: direccion,
    );

    if (user != null) {
      _user = user;
      notifyListeners();
      return true;
    }
    return false;
  }
}