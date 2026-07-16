// lib/features/admin/auth/admin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart'; // Usaremos uno temporal o crearemos uno específico

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _loginAdmin() async {
    setState(() => _isLoading = true);

    // Por ahora usamos el mismo AuthProvider (luego podemos separarlo)
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .login(_emailController.text.trim(), _passwordController.text);

    setState(() => _isLoading = false);

    if (success) {
      context.go('/admin/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales de administrador incorrectas'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F1E9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 100, color: Color(0xFFD4AF37)),
              const SizedBox(height: 24),
              const Text('Panel de Administración', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Estilo Dorado', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Usuario o Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginAdmin,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Ingresar al Panel Admin', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}