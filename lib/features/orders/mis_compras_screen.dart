// lib/features/orders/mis_compras_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int? _cancellingId;

  final _filtroId = TextEditingController();
  String _rango = '1y';

  static const _rangos = <(String key, String label)>[
    ('all', 'Todas'),
    ('last', 'Última compra'),
    ('30d', '30 días'),
    ('3m', '3 meses'),
    ('1y', 'Último año'),
  ];

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
        _error = 'No se pudieron cargar tus pedidos.\n${OrderService.errorMessage(e)}';
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
    if (_rango == 'all') return arr;
    if (_rango == 'last') {
      return arr.take(1).toList();
    }
    final now = DateTime.now();
    final cutoff = switch (_rango) {
      '30d' => now.subtract(const Duration(days: 30)),
      '3m' => DateTime(now.year, now.month - 3, now.day),
      _ => DateTime(now.year - 1, now.month, now.day),
    };
    arr = arr.where((p) {
      if (p.fechaPedido == null) return true;
      final d = DateTime.tryParse(p.fechaPedido!);
      if (d == null) return true;
      return !d.isBefore(cutoff);
    }).toList();
    return arr;
  }

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  Future<void> _cancelar(PedidoListItem p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text('¿Cancelar el pedido #${p.idPedido}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _cancellingId = p.idPedido);
    try {
      await _order.cancelar(p.idPedido, motivo: 'Cancelado por el cliente');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido #${p.idPedido} cancelado'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cancelar: ${OrderService.errorMessage(e)}'),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
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
              'Los pedidos pendientes se pueden pagar o cancelar. '
              'El comprobante PDF/XML solo aparece cuando el pedido está pagado.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _filtroId,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Buscar por N° de pedido',
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filtroId.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar número',
                        onPressed: () {
                          _filtroId.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final r in _rangos)
                  ChoiceChip(
                    label: Text(r.$2, style: const TextStyle(fontSize: 13)),
                    selected: _rango == r.$1,
                    selectedColor: _gold,
                    onSelected: (_) => setState(() => _rango = r.$1),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  list.isEmpty
                      ? (_data.isEmpty
                          ? ''
                          : 'Ningún pedido en este periodo. Prueba “Todas” o “Último año”.')
                      : '${list.length} pedido${list.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _gold))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      )
                    : RefreshIndicator(
                        color: _gold,
                        onRefresh: _cargar,
                        child: list.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 80),
                                  Icon(
                                    _data.isEmpty
                                        ? Icons.shopping_bag_outlined
                                        : Icons.filter_alt_off_outlined,
                                    size: 90,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: Text(
                                      _data.isEmpty
                                          ? 'Aún no tienes compras online'
                                          : 'No hay pedidos en este filtro',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      child: Text(
                                        _data.isEmpty
                                            ? 'Cuando compres, verás aquí el estado y el detalle de cada pedido.'
                                            : 'Cambia el periodo (Todas / Último año) o limpia el N° de pedido.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: FilledButton(
                                      onPressed: _data.isEmpty
                                          ? () => context.go('/home')
                                          : () => setState(() {
                                                _filtroId.clear();
                                                _rango = 'all';
                                              }),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _gold,
                                        foregroundColor: Colors.black87,
                                      ),
                                      child: Text(_data.isEmpty ? 'Ir a comprar' : 'Ver todas'),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final p = list[index];
                                  final pendiente = p.estado.toLowerCase() == 'pendiente';
                                  final canPayOnline = pendiente &&
                                      (p.formaPago ?? '').toLowerCase() != 'efectivo';
                                  final cancelling = _cancellingId == p.idPedido;
                                  final hasCpe = !pendiente &&
                                      p.comprobanteNumero != null &&
                                      (p.comprobanteNumero ?? 0) > 0 &&
                                      (p.comprobanteTipo == 'BO' || p.comprobanteTipo == 'FA');

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
                                            if (hasCpe && p.friendly != null)
                                              Text(
                                                'Comprobante: ${p.friendly}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green,
                                                ),
                                              ),
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
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: [
                                                FilledButton.tonal(
                                                  onPressed: () =>
                                                      context.push('/resumen/${p.idPedido}'),
                                                  child: const Text('Ver detalle'),
                                                ),
                                                if (canPayOnline)
                                                  FilledButton(
                                                    onPressed: () => context.push(
                                                      '/pagar-pedido/${p.idPedido}',
                                                      extra: {
                                                        'total': p.total,
                                                        'formaPago': p.formaPago,
                                                      },
                                                    ),
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: _gold,
                                                      foregroundColor: Colors.black87,
                                                    ),
                                                    child: const Text('Pagar'),
                                                  ),
                                                if (pendiente)
                                                  TextButton(
                                                    onPressed:
                                                        cancelling ? null : () => _cancelar(p),
                                                    child: cancelling
                                                        ? const SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                        : Text(
                                                            'Cancelar',
                                                            style: TextStyle(
                                                              color: Colors.red.shade700,
                                                            ),
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
