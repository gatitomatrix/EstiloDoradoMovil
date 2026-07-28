// lib/features/orders/mis_compras_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; 
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
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/pedidos/mios');
      setState(() {
        _pedidos = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar pedidos: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatTotal(dynamic total) {
    if (total == null) return '0.00';
    final valor = double.tryParse(total.toString()) ?? 0.0;
    return valor.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compras'),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'), // ← Aquí está el cambio
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPedidos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            )
          : RefreshIndicator(
              onRefresh: _cargarPedidos,
              color: const Color(0xFFD4AF37),
              child: _pedidos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey),
                          SizedBox(height: 24),
                          Text(
                            'Aún no tienes compras',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tu primer pedido aparecerá aquí',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _pedidos.length,
                      itemBuilder: (context, index) {
                        final pedido = _pedidos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Color(0xFFD4AF37),
                                size: 32,
                              ),
                            ),
                            title: Text(
                              'Pedido #${pedido['id_pedido'] ?? pedido['id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fecha: ${pedido['fecha_pedido'] ?? 'Sin fecha'}'),
                                Text('Total: S/ ${_formatTotal(pedido['total'])}'),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(
                                (pedido['estado'] ?? 'pendiente').toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: _getEstadoColor(pedido['estado']?.toString()),
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Detalle del pedido #${pedido['id_pedido']} (próximamente)',
                                  ),
                                ),
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
      case 'pagado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'enviado':
        return Colors.blue;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}