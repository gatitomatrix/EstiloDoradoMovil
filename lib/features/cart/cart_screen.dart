// lib/features/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final items = cartProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildCartItem(context, item, cartProvider);
                    },
                  ),
                ),

                // Resumen y botón de pago
                _buildBottomSummary(context, cartProvider),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
          SizedBox(height: 16),
          Text('Tu carrito está vacío', style: TextStyle(fontSize: 20)),
          Text('Agrega productos desde la tienda', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.imagenUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'S/ ${item.precio.toStringAsFixed(2)} x ${item.cantidad}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/ ${(item.precio * item.cantidad).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ],
              ),
            ),

            // Controles de cantidad
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => cartProvider.updateQuantity(item.id, item.cantidad - 1),
                ),
                Text('${item.cantidad}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => cartProvider.updateQuantity(item.id, item.cantidad + 1),
                ),
              ],
            ),

            // Eliminar
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => cartProvider.removeItem(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Column(
        children: [
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.push('/checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continuar con la compra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}