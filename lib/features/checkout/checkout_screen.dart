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
    final success = await cartProvider.realizarPedido(
      direccion: _direccionController.text.trim(),
      metodoPago: _metodoPago,
      observacion: _observacionController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pedido realizado con éxito!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/mis-compras');
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
    final cartProvider = Provider.of<CartProvider>(context);
    final items = cartProvider.items;

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
              // Resumen del Pedido
              const Text('Resumen del Pedido', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              ),

              const SizedBox(height: 16),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total a pagar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    'S/ ${cartProvider.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Dirección
              const Text('Dirección de Entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección completa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) => value!.trim().isEmpty ? 'Ingrese la dirección de entrega' : null,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Método de Pago
              const Text('Método de Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPaymentOption('yape', 'Yape', Icons.phone_android),
              _buildPaymentOption('tarjeta', 'Tarjeta (Visa / Mastercard)', Icons.credit_card),
              _buildPaymentOption('efectivo', 'Efectivo', Icons.money),

              const SizedBox(height: 24),

              // Observaciones
              const Text('Observaciones (opcional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observacionController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Dejar en portería, llamar al llegar...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 40),

              // Botón Confirmar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmarPedido,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CONFIRMAR PEDIDO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: RadioListTile<String>(
        value: value,
        groupValue: _metodoPago,
        onChanged: (val) => setState(() => _metodoPago = val!),
        title: Text(title),
        secondary: Icon(icon, color: const Color(0xFFD4AF37)),
        activeColor: const Color(0xFFD4AF37),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}