// lib/features/orders/views/order_success_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String metodoPago;
  final double total;
  final int pedidoId;

  const OrderSuccessScreen({
    super.key,
    required this.metodoPago,
    required this.total,
    required this.pedidoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido Realizado'),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 120, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                '¡Pedido realizado con éxito!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Total: S/ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, color: Color(0xFFD4AF37)),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/resumen/$pedidoId'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Ver resumen del pedido', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/mis-compras'),
                  child: const Text('Ir a Mis compras'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
