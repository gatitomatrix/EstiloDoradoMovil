// lib/core/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;

  // Nueva variable para recordar a dónde quería ir después del login
  String? _nextRouteAfterLogin;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  String? get nextRouteAfterLogin => _nextRouteAfterLogin;

  /// Verifica si el usuario ya está autenticado al iniciar la app
  Future<void> checkAuth() async {
    _isLoggedIn = await _authService.isLoggedIn();
    notifyListeners();
  }

  /// Registro
  Future<bool> register(String nombre, String email, String password) async {
    final response = await _authService.register(nombre, email, password);
    if (response['success']) {
      _isLoggedIn = true;
      _user = response['user'];
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Login
  Future<bool> login(String email, String password) async {
    final response = await _authService.login(email, password);
    if (response['success']) {
      _isLoggedIn = true;
      _user = response['user'];
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _user = null;
    _nextRouteAfterLogin = null; // limpiamos también
    notifyListeners();
  }

  // ==================== NUEVOS MÉTODOS PARA REDIRECCIÓN ====================
  void setNextRouteAfterLogin(String route) {
    _nextRouteAfterLogin = route;
    notifyListeners();
  }

  void clearNextRouteAfterLogin() {
    _nextRouteAfterLogin = null;
    notifyListeners();
  }
} 