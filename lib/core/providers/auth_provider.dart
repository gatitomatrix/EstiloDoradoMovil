// lib/core/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  String? _nextRouteAfterLogin;
  String? _lastError;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  String? get nextRouteAfterLogin => _nextRouteAfterLogin;
  String? get lastError => _lastError;

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
        // Token inválido / servidor caído: limpiar sesión local
        await _authService.logout();
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
    _lastError = null;
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
      _lastError = null;
      notifyListeners();
      return true;
    }
    _lastError = response['error']?.toString() ?? 'No se pudo registrar';
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    final response = await _authService.login(email, password);

    if (response['success'] == true) {
      _isLoggedIn = true;
      _user = response['user'] is Map
          ? Map<String, dynamic>.from(response['user'] as Map)
          : null;
      _lastError = null;
      notifyListeners();
      return true;
    }
    _lastError = response['error']?.toString() ?? 'Credenciales incorrectas';
    notifyListeners();
    return false;
  }

  Future<bool> loginWithGoogle({
    String? idToken,
    String? accessToken,
    bool demo = false,
  }) async {
    _lastError = null;
    final response = await _authService.loginWithGoogle(
      idToken: idToken,
      accessToken: accessToken,
      demo: demo && (idToken == null || idToken.isEmpty) && (accessToken == null || accessToken.isEmpty),
    );

    if (response['success'] == true) {
      _isLoggedIn = true;
      _user = response['user'] is Map
          ? Map<String, dynamic>.from(response['user'] as Map)
          : null;
      _lastError = null;
      notifyListeners();
      return true;
    }
    _lastError = response['error']?.toString() ?? 'No se pudo iniciar con Google';
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _user = null;
    _nextRouteAfterLogin = null;
    _lastError = null;
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
    _lastError = null;
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
    _lastError = 'No se pudo actualizar el perfil';
    notifyListeners();
    return false;
  }
}
