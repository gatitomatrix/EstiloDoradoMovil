// lib/features/admin/clientes/admin_clientes_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class AdminClientesScreen extends StatefulWidget {
  const AdminClientesScreen({super.key});

  @override
  State<AdminClientesScreen> createState() => _AdminClientesScreenState();
}

class _AdminClientesScreenState extends State<AdminClientesScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _clientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    try {
      final response = await _api.get('/clientes');
      setState(() {
        _clientes = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando clientes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        backgroundColor: const Color(0xFFD4AF37),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nuevo cliente - Próximamente')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarClientes,
              child: ListView.builder(
                itemCount: _clientes.length,
                itemBuilder: (context, index) {
                  final cliente = _clientes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.person, size: 40, color: Color(0xFFD4AF37)),
                      title: Text('${cliente['nombre'] ?? ''} ${cliente['apellido'] ?? ''}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${cliente['email'] ?? 'Sin email'}'),
                          Text('Teléfono: ${cliente['telefono'] ?? 'Sin teléfono'}'),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ver detalle de ${cliente['nombre']} - Próximamente')),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}