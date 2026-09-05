// lib/features/account/mi_cuenta_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/input_formatters.dart';

class MiCuentaScreen extends StatefulWidget {
  const MiCuentaScreen({super.key});

  @override
  State<MiCuentaScreen> createState() => _MiCuentaScreenState();
}

class _MiCuentaScreenState extends State<MiCuentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmaController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _emailController.dispose();
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Si no hay sesión, mandar a login
    if (!auth.isLoggedIn) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    // Intenta refrescar desde API; si falla usa lo guardado
    final me = await _authService.me();
    final user = me ?? auth.user;

    if (!mounted) return;

    if (user != null) {
      _nombreController.text = (user['nombre'] ?? '').toString();
      _apellidoController.text = (user['apellido'] ?? '').toString();
      _telefonoController.text = (user['telefono'] ?? '').toString();
      _direccionController.text = (user['direccion'] ?? '').toString();
      _emailController.text = (user['email'] ?? '').toString();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final ok = await Provider.of<AuthProvider>(context, listen: false).updateProfile(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Datos actualizados' : 'No se pudo guardar'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _cambiarClave() async {
    final actual = _actualController.text;
    final nueva = _nuevaController.text;
    final conf = _confirmaController.text;
    if (nueva.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nueva clave debe tener al menos 6 caracteres'), backgroundColor: Colors.red),
      );
      return;
    }
    if (nueva != conf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La confirmación no coincide'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSaving = true);
    final res = await _authService.changePassword(actual: actual, nueva: nueva);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['success'] == true
            ? 'Contraseña actualizada'
            : (res['error']?.toString() ?? 'No se pudo cambiar. Si usas Google, recupera con el código del correo.')),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (res['success'] == true) {
      _actualController.clear();
      _nuevaController.clear();
      _confirmaController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F1E9),
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos personales',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Actualiza tu información de perfil',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      inputFormatters: [
                        ...AppInputFormatters.personName,
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingrese su nombre';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _apellidoController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      inputFormatters: [
                        ...AppInputFormatters.personName,
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo (no editable)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        hintText: '9xxxxxxxx',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      inputFormatters: AppInputFormatters.phonePe,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return null;
                        if (!RegExp(r'^9\d{8}$').hasMatch(t)) {
                          return 'Celular: 9 dígitos empezando en 9';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _direccionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Contraseña',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Si solo entras con Google, usa “¿Olvidaste tu contraseña?” en el login.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _actualController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña actual',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nuevaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nueva (mín. 6)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar nueva',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _cambiarClave,
                        child: const Text('Cambiar contraseña'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/recuperar'),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/privacidad'),
                        child: const Text('Política de privacidad'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Guardar cambios',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}