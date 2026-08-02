// lib/features/orders/mis_compras_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/checkout_models.dart';
import '../../core/services/order_service.dart';

const _gold = Color(0xFFD4AF37);

class MisComprasScreen extends StatefulWidget {
  const MisComprasScreen({super.key});

  @override
  State<MisComprasScreen> createState() => _MisComprasScreenState();
}

class _MisComprasScreenState extends State<MisComprasScreen> {
  final _order = OrderService();
  List<PedidoListItem> _data = [];
  bool _loading = true;
  String? _error;

  final _filtroId = TextEditingController();
  String _rango = '1y'; // 1y | 3m | last

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _filtroId.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _order.listMine();
      if (!mounted) return;
      setState(() {
        _data = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar tus pedidos.';
        _loading = false;
      });
    }
  }

  List<PedidoListItem> get _filtered {
    var arr = List<PedidoListItem>.from(_data);
    final q = int.tryParse(_filtroId.text.trim());
    if (q != null) {
      arr = arr.where((p) => p.idPedido == q).toList();
    }
    if (_rango == 'last') {
      return arr.take(1).toList();
    }
    final months = _rango == '3m' ? 3 : 12;
    final cutoff = DateTime.now().subtract(Duration(days: 30 * months));
    arr = arr.where((p) {
      if (p.fechaPedido == null) return true;
      final d = DateTime.tryParse(p.fechaPedido!);
      if (d == null) return true;
      return d.isAfter(cutoff);
    }).toList();
    return arr;
  }

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis compras'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'El estado del pedido cambiará según el proceso de compra y el tiempo de entrega o recojo en tienda.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filtroId,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'N° de pedido',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _rango,
                  items: const [
                    DropdownMenuItem(value: '1y', child: Text('Último año')),
                    DropdownMenuItem(value: '3m', child: Text('3 meses')),
                    DropdownMenuItem(value: 'last', child: Text('Última')),
                  ],
                  onChanged: (v) => setState(() => _rango = v ?? '1y'),
                ),
                IconButton(
                  tooltip: 'Limpiar',
                  onPressed: () {
                    _filtroId.clear();
                    setState(() => _rango = '1y');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _gold))
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                        color: _gold,
                        onRefresh: _cargar,
                        child: list.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Icon(Icons.shopping_bag_outlined, size: 90, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Center(
                                    child: Text(
                                      '¡Oh! Aún no tienes compras online.',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final p = list[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => context.push('/resumen/${p.idPedido}'),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Pedido #${p.idPedido}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                _estadoChip(p.estado),
                                              ],
                                            ),
                                            if (p.productoLabel != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                p.productoLabel!,
                                                style: TextStyle(color: Colors.grey[700]),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Text('Fecha: ${_fmtDate(p.fechaPedido)}'),
                                            Text('Entrega: ${p.direccionEntrega ?? '—'}'),
                                            Text('Pago: ${p.formaPago ?? '—'}'),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text(
                                                  'Total: S/ ${p.total.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: _gold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const Spacer(),
                                                OutlinedButton(
                                                  onPressed: () =>
                                                      context.push('/resumen/${p.idPedido}'),
                                                  child: const Text('Resumen'
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Para cualquier reclamo usa el N° de pedido. ¡Gracias por comprar con nosotros!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoChip(String estado) {
    Color c;
    switch (estado.toLowerCase()) {
      case 'pagado':
      case 'entregado':
      case 'completado':
        c = Colors.green;
        break;
      case 'pendiente':
        c = Colors.orange;
        break;
      case 'cancelado':
        c = Colors.red;
        break;
      default:
        c = Colors.blueGrey;
    }
    return Chip(
      label: Text(
        estado.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      backgroundColor: c,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
