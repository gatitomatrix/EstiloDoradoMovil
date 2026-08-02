// lib/features/checkout/confirmar_entrega_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/checkout_models.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/checkout_provider.dart';

const _gold = Color(0xFFD4AF37);

class ConfirmarEntregaScreen extends StatelessWidget {
  const ConfirmarEntregaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final subtotal = cart.subtotal;

    if (checkout.mode == DeliveryMode.none) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/entrega');
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar entrega')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: _gold),
              title: const Text('Dirección'),
              subtitle: Text(checkout.address?.display ?? '–'),
              trailing: TextButton(
                onPressed: () => context.push('/entrega'),
                child: const Text('Cambiar'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                RadioListTile<DeliveryMode>(
                  value: DeliveryMode.storePickup,
                  groupValue: checkout.mode,
                  activeColor: _gold,
                  title: const Text('Retiro en tienda', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Recoge en tienda de inmediato y de forma segura.'),
                  secondary: const Text('S/ 0', style: TextStyle(fontWeight: FontWeight.bold, color: _gold)),
                  onChanged: (_) => checkout.setMode(DeliveryMode.storePickup),
                ),
                const Divider(height: 1),
                RadioListTile<DeliveryMode>(
                  value: DeliveryMode.express,
                  groupValue: checkout.mode,
                  activeColor: _gold,
                  title: const Text('Envío a dirección', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                    'Envío a tu dirección de 1 a 2 días según ubicación y horarios de reparto.',
                  ),
                  secondary: const Text('S/ 20', style: TextStyle(fontWeight: FontWeight.bold, color: _gold)),
                  onChanged: (_) {
                    if (checkout.address == null ||
                        checkout.address!.via == 'Retiro en tienda') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Primero ingresa una dirección de envío'),
                        ),
                      );
                      context.push('/entrega');
                      return;
                    }
                    checkout.setMode(DeliveryMode.express);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Productos', cart.subtotal),
                  _row('Descuentos', -checkout.discount, green: true),
                  _row('Entregas', checkout.fee),
                  const Divider(),
                  _row('Total', checkout.totalWith(subtotal), bold: true),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: checkout.canPay
                          ? () => context.push('/pago')
                          : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                      child: const Text(
                        'Ir a pagar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double amount, {bool green = false, bool bold = false}) {
    final prefix = amount < 0 || green ? '- S/ ' : 'S/ ';
    final value = amount.abs().toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text(
            '$prefix$value',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: green ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
