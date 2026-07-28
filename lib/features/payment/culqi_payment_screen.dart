// lib/features/payment/culqi_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        title: const Text('Pago con Culqi'),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.credit_card, size: 100, color: Color(0xFFD4AF37)),
              const SizedBox(height: 24),
              const Text(
                'Pantalla de Pago Culqi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Pedido #$pedidoId',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: S/ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
              ),
              const SizedBox(height: 40),
              const Text(
                'Esta pantalla se conectará con Culqi próximamente.\nPor ahora es solo una vista de prueba.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Integración con Culqi en desarrollo'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Pagar ahora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/mis-compras'),
                child: const Text('Volver a Mis Compras'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}