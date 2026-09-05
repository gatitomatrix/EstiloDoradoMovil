// lib/features/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/app_router.dart';
import '../../core/config/api_config.dart';
import '../../core/services/google_sign_in_helper.dart';
import '../../core/utils/app_snackbar.dart';
import 'privacidad_screen.dart';

const _gold = Color(0xFFD4AF37);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final success = await auth.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      apellido: _apellidoController.text.trim().isEmpty
          ? null
          : _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final uid = auth.user?['id_cliente'];
      final id = uid is int ? uid : int.tryParse(uid?.toString() ?? '');
      await cart.bindUser(id);
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada! Ya puedes comprar.'),
          backgroundColor: Colors.green,
        ),
      );
      final next = AppRouter.resolvePostLoginRoute(auth.nextRouteAfterLogin);
      auth.clearNextRouteAfterLogin();
      context.go(next);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError ?? 'Error al registrar'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _registerGoogle() async {
    setState(() => _googleLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);
    var success = false;
    try {
      if (ApiConfig.googleWebClientId.isNotEmpty) {
        final t = await GoogleSignInHelper.signIn();
        success = await auth.loginWithGoogle(
          idToken: t.idToken,
          accessToken: t.accessToken,
        );
      } else {
        success = await auth.loginWithGoogle(demo: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _googleLoading = false);
        AppSnackBar.err(context, e.toString().replaceFirst('Exception: ', ''));
      }
      return;
    }
    if (!mounted) return;
    if (success) {
      final uid = auth.user?['id_cliente'];
      final id = uid is int ? uid : int.tryParse(uid?.toString() ?? '');
      await cart.bindUser(id);
      if (!mounted) return;
      setState(() => _googleLoading = false);
      final next = AppRouter.resolvePostLoginRoute(auth.nextRouteAfterLogin);
      auth.clearNextRouteAfterLogin();
      context.go(next);
      return;
    }
    setState(() => _googleLoading = false);
    AppSnackBar.err(context, auth.lastError ?? 'No se pudo entrar con Google');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: _gold,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
      ),
      backgroundColor: const Color(0xFFF8F1E9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Únete a Estilo Dorado',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crea tu cuenta para comprar y ver tus pedidos.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  inputFormatters: AppInputFormatters.personName,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese su nombre';
                    }
                    if (value.trim().length < 2) {
                      return 'Nombre demasiado corto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _apellidoController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Apellido (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  inputFormatters: AppInputFormatters.personName,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    hintText: '9xxxxxxxx',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  inputFormatters: AppInputFormatters.phonePe,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return null;
                    if (!RegExp(r'^9\d{8}$').hasMatch(v)) {
                      return 'Celular peruano: 9 dígitos empezando en 9';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese su correo';
                    }
                    final email = value.trim();
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                      return 'Correo no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña *',
                    helperText: 'Mínimo 6 caracteres',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese una contraseña';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme su contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _googleLoading) ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Crear cuenta',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: (_isLoading || _googleLoading) ? null : _registerGoogle,
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4285F4),
                        fontSize: 18,
                      ),
                    ),
                    label: Text(
                      _googleLoading ? 'Conectando…' : 'Crear cuenta con Gmail',
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
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                  ),
                ),
                const SizedBox(height: 4),
                const PrivacidadAviso(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
