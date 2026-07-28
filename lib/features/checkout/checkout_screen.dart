// lib/features/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _direccionController = TextEditingController();
  final _observacionController = TextEditingController();
  String _metodoPago = 'yape';
  bool _isLoading = false;

  @override
  void dispose() {
    _direccionController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _confirmarPedido() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Guardamos el total ANTES de llamar a realizarPedido
    final totalPedido = cartProvider.total;

    final pedidoId = await cartProvider.realizarPedido(
      direccion: _direccionController.text.trim(),
      metodoPago: _metodoPago,
      observacion: _observacionController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (pedidoId != null) {
      context.push(
        '/order-success',
        extra: {
          'metodoPago': _metodoPago,
          'total': totalPedido,
          'pedidoId': pedidoId,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar el pedido'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen del Pedido',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  final items = cartProvider.items;
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.nombre} × ${item.cantidad}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                Text(
                                  'S/ ${(item.precio * item.cantidad).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total a pagar',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'S/ ${cartProvider.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              const Text(
                'Dirección de Entrega',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección completa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Ingrese la dirección de entrega' : null,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              const Text(
                'Método de Pago',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPaymentButton('yape', 'Yape', Icons.phone_android),
              _buildPaymentButton('tarjeta', 'Tarjeta', Icons.credit_card),
              _buildPaymentButton('efectivo', 'Efectivo', Icons.money),

              const SizedBox(height: 24),

              const Text(
                'Observaciones (opcional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observacionController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Dejar en portería...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmarPedido,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'CONFIRMAR PEDIDO',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton(String value, String title, IconData icon) {
    final isSelected = _metodoPago == value;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => setState(() => _metodoPago = value),
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFD4AF37) : Colors.grey,
        ),
        title: Text(title),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37))
            : null,
      ),
    );
  }
}