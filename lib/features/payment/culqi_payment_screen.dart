// lib/features/payment/culqi_payment_screen.dart
// Compat: la pantalla antigua de Culqi ya no se usa en el flujo principal.
// Redirige al resumen del pedido (pago real va por /pago → /pedidos/confirmar).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _gold = Color(0xFFD4AF37);

class CulqiPaymentScreen extends StatelessWidget {
  final int pedidoId;
  final double total;

  const CulqiPaymentScreen({
    super.key,
    required this.pedidoId,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido'),
        backgroundColor: _gold,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 88, color: _gold),
              const SizedBox(height: 20),
              Text(
                'Pedido #$pedidoId',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: S/ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, color: _gold, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Text(
                'El pago con Yape/tarjeta ahora se completa en el flujo de compra '
                '(Entrega → Pago). Si este pedido quedó pendiente, revisa el detalle '
                'para cancelarlo o consulta en tienda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => context.go('/resumen/$pedidoId'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Ver detalle del pedido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/mis-compras'),
                child: const Text('Volver a Mis compras'),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Ir a la tienda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
