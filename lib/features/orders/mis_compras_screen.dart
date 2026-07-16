// lib/features/orders/mis_compras_screen.dart
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class MisComprasScreen extends StatefulWidget {
  const MisComprasScreen({super.key});

  @override
  State<MisComprasScreen> createState() => _MisComprasScreenState();
}

class _MisComprasScreenState extends State<MisComprasScreen> {
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
      final response = await _api.get('/pedidos/mis-pedidos');
      setState(() {
        _pedidos = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar pedidos: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Compras')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pedidos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aún no tienes compras', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarPedidos,
                  child: ListView.builder(
                    itemCount: _pedidos.length,
                    itemBuilder: (context, index) {
                      final pedido = _pedidos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long, color: Color(0xFFD4AF37), size: 40),
                          title: Text('Pedido #${pedido['id_pedido']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha: ${pedido['fecha_pedido'] ?? 'Sin fecha'}'),
                              Text('Total: S/ ${pedido['total']?.toString() ?? '0.00'}'),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              (pedido['estado'] ?? 'pendiente').toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _getEstadoColor(pedido['estado']),
                          ),
                          onTap: () {
                            // Puedes crear una pantalla de detalle después
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ver detalle del pedido #${pedido['id_pedido']}')),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _getEstadoColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'completado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}