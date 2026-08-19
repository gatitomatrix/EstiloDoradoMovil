// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/app_router.dart';
import '../../core/config/api_config.dart';
import '../../core/services/google_sign_in_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _googleLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _afterLoginOk(AuthProvider authProvider) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final uid = authProvider.user?['id_cliente'];
    final id = uid is int ? uid : int.tryParse(uid?.toString() ?? '');
    await cart.bindUser(id);

    if (!mounted) return;
    AppSnackBar.ok(context, 'Sesión iniciada');

    final nextRoute = AppRouter.resolvePostLoginRoute(authProvider.nextRouteAfterLogin);
    authProvider.clearNextRouteAfterLogin();
    context.go(nextRoute);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _isLoading = false);
      await _afterLoginOk(authProvider);
    } else {
      setState(() => _isLoading = false);
      AppSnackBar.err(context, authProvider.lastError ?? 'Credenciales incorrectas');
    }
  }

  /// Gmail real si hay Client ID; si no, demo local.
  Future<void> _loginGoogle() async {
    setState(() => _googleLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    var success = false;
    try {
      if (ApiConfig.googleWebClientId.isNotEmpty) {
        final t = await GoogleSignInHelper.signIn();
        success = await authProvider.loginWithGoogle(
          idToken: t.idToken,
          accessToken: t.accessToken,
        );
      } else {
        success = await authProvider.loginWithGoogle(demo: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _googleLoading = false);
        AppSnackBar.err(context, e.toString().replaceFirst('Exception: ', ''));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (success) {
      await _afterLoginOk(authProvider);
    } else {
      AppSnackBar.err(context, authProvider.lastError ?? 'No se pudo iniciar con Google');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F1E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4AF37),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Iniciar Sesión'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_empresa.jpeg',
                  height: 120,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.storefront,
                    size: 100,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bienvenido',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa para continuar tu compra',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                      return 'Correo no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading || _googleLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Ingresar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading || _googleLoading ? null : _loginGoogle,
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4285F4),
                        fontSize: 18,
                      ),
                    ),
                    label: Text(
                      _googleLoading ? 'Conectando…' : 'Continuar con Google',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFE7DAC6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ApiConfig.googleWebClientId.isEmpty
                      ? 'Sin Client ID: entra en modo demo. Para Gmail, pega GOOGLE_WEB_CLIENT_ID.'
                      : 'Se abrirá tu cuenta de Google (internet).',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => context.push('/recuperar'),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/registro'),
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
                TextButton(
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false)
                        .clearNextRouteAfterLogin();
                    context.go('/home');
                  },
                  child: const Text('Continuar sin iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
