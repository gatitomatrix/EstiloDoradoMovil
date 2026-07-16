// lib/features/admin/productos/admin_productos_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class AdminProductosScreen extends StatefulWidget {
  const AdminProductosScreen({super.key});

  @override
  State<AdminProductosScreen> createState() => _AdminProductosScreenState();
}

class _AdminProductosScreenState extends State<AdminProductosScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final response = await _api.get('/productos');
      setState(() {
        _productos = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando productos: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        backgroundColor: const Color(0xFFD4AF37),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Abrir formulario para nuevo producto
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nuevo producto - Próximamente')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final prod = _productos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: prod['imagen_url'] != null
                        ? Image.network(prod['imagen_url'], width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 50),
                    title: Text(prod['nombre'] ?? 'Sin nombre'),
                    subtitle: Text('S/ ${prod['precio_venta'] ?? '0.00'} | Stock: ${prod['stock'] ?? 0}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editarProducto(prod),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarProducto(prod['id_producto']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _editarProducto(dynamic producto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editar ${producto['nombre']} - Próximamente')),
    );
  }

  void _eliminarProducto(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto eliminado (simulado)')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}