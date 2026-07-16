// lib/features/products/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/product_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    final Product? product = productProvider.products
        .cast<Product?>()
        .firstWhere((p) => p?.id == widget.productId, orElse: () => null);

    // Producto no encontrado
    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Producto no encontrado'),
          backgroundColor: const Color(0xFFD4AF37),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Este producto no existe', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.nombre, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFD4AF37),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen principal con Hero
            Hero(
              tag: 'product-${product.id}',
              child: CachedNetworkImage(
                imageUrl: product.imagenUrl ?? '',
                width: double.infinity,
                height: 320,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 320,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 320,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 100),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    product.nombre,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Precio
                  Text(
                    'S/ ${product.precioVenta.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: product.stock > 0 ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.stock > 0 
                          ? 'En stock (${product.stock} disponibles)' 
                          : 'Agotado',
                      style: TextStyle(
                        color: product.stock > 0 ? Colors.green[800] : Colors.red[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Descripción
                  const Text(
                    'Descripción',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.descripcion ?? 'No hay descripción disponible para este producto.',
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),

                  const SizedBox(height: 40),

                  // Botón Agregar al Carrito
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: product.stock > 0
                          ? () {
                              cartProvider.addItem(
                                CartItem(
                                  id: product.id,
                                  nombre: product.nombre,
                                  precio: product.precioVenta,
                                  imagenUrl: product.imagenUrl ?? '',
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.nombre} agregado al carrito'),
                                  backgroundColor: const Color(0xFFD4AF37),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        product.stock > 0 ? 'Agregar al carrito' : 'Producto agotado',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}