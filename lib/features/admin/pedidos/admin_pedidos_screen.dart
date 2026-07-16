// lib/features/admin/pedidos/admin_pedidos_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});

  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _pedidos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    try {
      final response = await _api.get('/pedidos');
      setState(() {
        _pedidos = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando pedidos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarEstado(int pedidoId, String nuevoEstado) async {
    try {
      await _api.put('/pedidos/$pedidoId/estado', {'estado': nuevoEstado});
      _cargarPedidos(); // Recargar lista
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a $nuevoEstado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar estado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarPedidos,
              child: ListView.builder(
                itemCount: _pedidos.length,
                itemBuilder: (context, index) {
                  final pedido = _pedidos[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long, size: 40, color: Color(0xFFD4AF37)),
                      title: Text('Pedido #${pedido['id_pedido']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente: ${pedido['nombre_cliente'] ?? 'Sin nombre'}'),
                          Text('Total: S/ ${pedido['total']?.toString() ?? '0.00'}'),
                          Text('Fecha: ${pedido['fecha_pedido'] ?? ''}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => _cambiarEstado(pedido['id_pedido'], value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'pendiente', child: Text('Pendiente')),
                          const PopupMenuItem(value: 'procesando', child: Text('Procesando')),
                          const PopupMenuItem(value: 'completado', child: Text('Completado')),
                          const PopupMenuItem(value: 'cancelado', child: Text('Cancelado')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}