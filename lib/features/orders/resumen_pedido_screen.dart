// lib/features/orders/resumen_pedido_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/checkout_models.dart';
import '../../core/services/order_service.dart';
import '../../core/utils/tarifa_envio.dart';

const _gold = Color(0xFFD4AF37);

class ResumenPedidoScreen extends StatefulWidget {
  final int pedidoId;
  final bool ventaOk;
  final ComprobanteOut? comprobanteExtra;

  const ResumenPedidoScreen({
    super.key,
    required this.pedidoId,
    this.ventaOk = false,
    this.comprobanteExtra,
  });

  @override
  State<ResumenPedidoScreen> createState() => _ResumenPedidoScreenState();
}

class _ResumenPedidoScreenState extends State<ResumenPedidoScreen> {
  final _order = OrderService();
  ConfirmarRes? _data;
  String? _error;
  bool _loading = true;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.ventaOk) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccess());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _order.getById(widget.pedidoId);
      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'No se pudo cargar el pedido #${widget.pedidoId}.\n${OrderService.errorMessage(e)}';
        _loading = false;
      });
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 72),
            SizedBox(height: 12),
            Text(
              '¡Venta exitosa!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Gracias por tu compra. Puedes revisar el comprobante aquí mismo.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String? url, String tipo) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$tipo aún no disponible')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir $tipo')),
      );
    }
  }

  Future<void> _cancelar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text(
          '¿Seguro que deseas cancelar el pedido #${widget.pedidoId}? '
          'Solo se puede cancelar si aún no está pagado.',
        ),
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

    setState(() => _cancelling = true);
    try {
      final res = await _order.cancelar(widget.pedidoId, motivo: 'Cancelado por el cliente');
      if (!mounted) return;
      setState(() {
        _data = res;
        _cancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido cancelado'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cancelar: ${OrderService.errorMessage(e)}'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  bool get _isPendiente =>
      (_data?.estado ?? '').toLowerCase() == 'pendiente';

  bool get _canCancel => _isPendiente;

  bool get _canPayOnline {
    if (!_isPendiente) return false;
    final fp = (_data?.formaPago ?? '').toLowerCase();
    // Efectivo se paga en tienda; yape/tarjeta (o sin forma) pueden pagarse en app
    return fp != 'efectivo';
  }

  bool get _isCashPending {
    if (!_isPendiente) return false;
    return (_data?.formaPago ?? '').toLowerCase() == 'efectivo';
  }

  /// Solo mostrar comprobante si el pedido está pagado/entregado y hay CPE real.
  bool get _showComprobante {
    final d = _data;
    if (d == null) return false;
    final estado = d.estado.toLowerCase();
    if (!const {'pagado', 'enviado', 'entregado', 'completado'}.contains(estado)) {
      return false;
    }
    final comp = d.comprobante ?? widget.comprobanteExtra;
    if (comp == null) return false;
    if (comp.tipo != 'FA' && comp.tipo != 'BO') return false;
    if (comp.numero <= 0) return false;
    return true;
  }

  void _irAPagar() {
    final d = _data!;
    context.push(
      '/pagar-pedido/${d.idPedido}',
      extra: {
        'total': d.total,
        'formaPago': d.formaPago,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.pedidoId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mis-compras'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
                        TextButton(
                          onPressed: () => context.go('/mis-compras'),
                          child: const Text('Volver a Mis compras'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _data!;
    final comp = d.comprobante ?? widget.comprobanteExtra;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(d.estado.toUpperCase()),
                      backgroundColor: _estadoColor(d.estado).withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: _estadoColor(d.estado),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'S/ ${d.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _info('Fecha', d.fechaPedido ?? '—'),
                _info('Pago', d.formaPago.isEmpty ? '—' : d.formaPago),
                _info('Entrega', d.direccionEntrega ?? '—'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Detalle de productos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (d.detalles == null || d.detalles!.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text('Sin líneas de producto en este pedido.'),
                )
              else
                ...d.detalles!.asMap().entries.map((e) {
                  final i = e.key;
                  final det = e.value;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _gold.withValues(alpha: 0.15),
                      child: Text('${i + 1}', style: const TextStyle(color: _gold)),
                    ),
                    title: Text(det.producto ?? 'Producto #${det.idProducto}'),
                    subtitle: Text(
                      '${det.cantidad} × S/ ${det.precioUnitario.toStringAsFixed(2)}',
                    ),
                    trailing: Text(
                      'S/ ${(det.subtotal ?? det.cantidad * det.precioUnitario).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Comprobante solo si la compra está pagada y hay CPE real
        if (_showComprobante && comp != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comp.tipo == 'FA' ? 'FACTURA ELECTRÓNICA' : 'BOLETA ELECTRÓNICA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(comp.friendly, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openFile(d.sunatPdf ?? comp.pdf, 'PDF'),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('PDF'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openFile(d.sunatXml ?? comp.xml, 'XML'),
                        icon: const Icon(Icons.code),
                        label: const Text('XML'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openFile(d.sunatCdr ?? comp.cdr, 'CDR'),
                        icon: const Icon(Icons.mail_outline),
                        label: const Text('CDR'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else if (_isCashPending)
          Card(
            color: Colors.amber.shade50,
            child: ListTile(
              leading: const Icon(Icons.storefront, color: Colors.orange),
              title: const Text('Pago en efectivo (retiro en tienda)'),
              subtitle: Text(
                'Paga al recoger en ${TarifaEnvio.direccionTienda}. Mientras esté pendiente puedes cancelar el pedido.',
              ),
            ),
          )
        else if (_isPendiente)
          Card(
            color: Colors.orange.shade50,
            child: const ListTile(
              leading: Icon(Icons.pending_actions, color: Colors.orange),
              title: Text('Pedido pendiente de pago'),
              subtitle: Text(
                'Aún no hay comprobante electrónico. Completa el pago o cancela el pedido.',
              ),
            ),
          ),

        // Acciones de pendiente
        if (_canPayOnline) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _irAPagar,
              icon: const Icon(Icons.credit_card),
              label: const Text(
                'Pagar ahora',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black87,
              ),
            ),
          ),
        ],
        if (_canCancel) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _cancelling ? null : _cancelar,
              icon: _cancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined, color: Colors.red),
              label: Text(
                _cancelling ? 'Cancelando…' : 'Cancelar pedido',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text(
              'Seguir comprando',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => context.go('/mis-compras'),
            child: const Text('Ver mis compras'),
          ),
        ),
      ],
    );
  }

  Widget _info(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(v)),
          ],
        ),
      );

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
      case 'entregado':
      case 'completado':
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
