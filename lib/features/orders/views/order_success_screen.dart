// lib/features/orders/views/order_success_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/checkout_models.dart';
import '../../../core/utils/tarifa_envio.dart';

const _gold = Color(0xFFD4AF37);

class OrderSuccessScreen extends StatelessWidget {
  final String metodoPago;
  final double total;
  final int pedidoId;
  final ComprobanteOut? comprobante;
  final String? sunatPdf;
  final String? sunatXml;
  final String? sunatCdr;

  const OrderSuccessScreen({
    super.key,
    required this.metodoPago,
    required this.total,
    required this.pedidoId,
    this.comprobante,
    this.sunatPdf,
    this.sunatXml,
    this.sunatCdr,
  });

  bool get _hasCpe {
    final c = comprobante;
    if (c == null) return false;
    return (c.tipo == 'BO' || c.tipo == 'FA') && c.numero > 0;
  }

  Future<void> _open(BuildContext context, String? url, String label) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label aún no disponible. Ábrelo desde el detalle del pedido.')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir $label')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCash = metodoPago.toLowerCase() == 'efectivo';
    final pdf = sunatPdf ?? comprobante?.pdf;
    final xml = sunatXml ?? comprobante?.xml;
    final cdr = sunatCdr ?? comprobante?.cdr;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text('Compra exitosa'),
        backgroundColor: _gold,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 88, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Text(
              isCash ? '¡Pedido registrado!' : '¡Venta exitosa!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isCash
                  ? 'Tu pedido quedó pendiente de pago en tienda. Recoge en ${TarifaEnvio.direccionTienda}'
                  : 'Gracias por tu compra. Puedes descargar el comprobante o ver el detalle.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], height: 1.35),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Pedido', '#$pedidoId'),
                    _row('Total', 'S/ ${total.toStringAsFixed(2)}', highlight: true),
                    _row('Pago', metodoPago.isEmpty ? '—' : metodoPago),
                    if (_hasCpe)
                      _row(
                        'Comprobante',
                        comprobante!.friendly,
                      ),
                  ],
                ),
              ),
            ),
            if (_hasCpe && !isCash) ...[
              const SizedBox(height: 16),
              const Text(
                'Comprobante electrónico',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(context, pdf, 'PDF'),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(context, xml, 'XML'),
                      icon: const Icon(Icons.code),
                      label: const Text('XML'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(context, cdr, 'CDR'),
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('CDR'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.go(
                  '/resumen/$pedidoId',
                  extra: {
                    'ventaOk': false,
                    'comprobante': comprobante,
                  },
                ),
                icon: const Icon(Icons.receipt_long),
                label: const Text(
                  'Ver detalle del pedido',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => context.go('/mis-compras'),
                child: const Text('Ir a Mis compras'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Seguir comprando'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(k, style: TextStyle(color: Colors.grey[700])),
          const Spacer(),
          Text(
            v,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: highlight ? 18 : 15,
              color: highlight ? _gold : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
