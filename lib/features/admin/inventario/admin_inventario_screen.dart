// lib/features/admin/inventario/admin_inventario_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class AdminInventarioScreen extends StatefulWidget {
  const AdminInventarioScreen({super.key});

  @override
  State<AdminInventarioScreen> createState() => _AdminInventarioScreenState();
}

class _AdminInventarioScreenState extends State<AdminInventarioScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _movimientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarInventario();
  }

  Future<void> _cargarInventario() async {
    try {
      final response = await _api.get('/inventario');
      setState(() {
        _movimientos = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando inventario: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inventario'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarInventario,
              child: ListView.builder(
                itemCount: _movimientos.length,
                itemBuilder: (context, index) {
                  final mov = _movimientos[index];
                  final esEntrada = mov['tipo_movimiento'] == 'entrada';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                        color: esEntrada ? Colors.green : Colors.red,
                        size: 40,
                      ),
                      title: Text(mov['producto_nombre'] ?? 'Producto'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cantidad: ${mov['cantidad']}'),
                          Text('Fecha: ${mov['fecha'] ?? ''}'),
                          Text('Tipo: ${mov['tipo_movimiento']?.toUpperCase() ?? ''}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          mov['tipo_movimiento']?.toUpperCase() ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: esEntrada ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nuevo movimiento de inventario - Próximamente')),
          );
        },
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.add),
      ),
    );
  }
}