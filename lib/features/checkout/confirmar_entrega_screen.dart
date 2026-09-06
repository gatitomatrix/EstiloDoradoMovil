// lib/features/checkout/confirmar_entrega_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/checkout_models.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/checkout_provider.dart';
import '../../core/utils/tarifa_envio.dart';

const _gold = Color(0xFFD4AF37);

class ConfirmarEntregaScreen extends StatelessWidget {
  const ConfirmarEntregaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final subtotal = cart.subtotal;
    final expressTarifa = TarifaEnvio.costo(
      departamento: checkout.savedExpress?.departamento ?? checkout.address?.departamento,
      provincia: checkout.savedExpress?.provincia ?? checkout.address?.provincia,
      distrito: checkout.savedExpress?.distrito ?? checkout.address?.distrito,
      tipo: (checkout.savedExpress?.envioTipo ?? checkout.address?.envioTipo) == 'DOMICILIO'
          ? 'DOMICILIO'
          : 'AGENCIA',
    );

    // No redirigir en post-frame de forma agresiva (puede pisar otras pantallas).
    // Si no hay modo, se muestra CTA a Entrega.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar entrega'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/entrega'),
        ),
      ),
      body: checkout.mode == DeliveryMode.none
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Elige un tipo de entrega para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/entrega'),
                      child: const Text('Ir a Entrega'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/cart'),
                      child: const Text('Volver al carrito'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: _gold),
                    title: const Text('Dirección'),
                    subtitle: Text(
                      checkout.mode == DeliveryMode.storePickup
                          ? TarifaEnvio.textoRecojo
                          : (checkout.savedExpress?.display ?? checkout.address?.display ?? '–'),
                    ),
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
                      Container(
                        decoration: BoxDecoration(
                          color: checkout.mode == DeliveryMode.storePickup
                              ? _gold.withValues(alpha: 0.12)
                              : null,
                          border: Border(
                            left: BorderSide(
                              color: checkout.mode == DeliveryMode.storePickup
                                  ? _gold
                                  : Colors.transparent,
                              width: 4,
                            ),
                          ),
                        ),
                        child: RadioListTile<DeliveryMode>(
                        value: DeliveryMode.storePickup,
                        groupValue: checkout.mode,
                        activeColor: _gold,
                        title: const Text(
                          'Retiro en tienda',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Recoge en tienda de inmediato y de forma segura.\n📍 ${TarifaEnvio.direccionTienda}',
                        ),
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'S/ 0',
                              style: TextStyle(fontWeight: FontWeight.bold, color: _gold),
                            ),
                            if (checkout.mode == DeliveryMode.storePickup) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle, color: _gold),
                            ],
                          ],
                        ),
                        onChanged: (_) => checkout.setMode(DeliveryMode.storePickup),
                      ),
                      ),
                      const Divider(height: 1),
                      Container(
                        decoration: BoxDecoration(
                          color: checkout.mode == DeliveryMode.express
                              ? _gold.withValues(alpha: 0.12)
                              : null,
                          border: Border(
                            left: BorderSide(
                              color: checkout.mode == DeliveryMode.express
                                  ? _gold
                                  : Colors.transparent,
                              width: 4,
                            ),
                          ),
                        ),
                        child: RadioListTile<DeliveryMode>(
                        value: DeliveryMode.express,
                        groupValue: checkout.mode,
                        activeColor: _gold,
                        title: const Text(
                          'Envío a dirección',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Shalom a agencia o domicilio. Pasco: solo domicilio.\n${expressTarifa.etiqueta}',
                        ),
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'S/ ${expressTarifa.costo.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: _gold),
                            ),
                            if (checkout.mode == DeliveryMode.express) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle, color: _gold),
                            ],
                          ],
                        ),
                        onChanged: (_) {
                          final saved = checkout.savedExpress;
                          if (saved == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Primero ingresa una dirección de envío'),
                              ),
                            );
                            context.push('/entrega');
                            return;
                          }
                          checkout.setExpress(saved);
                        },
                      ),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                            ),
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
