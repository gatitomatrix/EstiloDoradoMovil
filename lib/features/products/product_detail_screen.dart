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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      final cart = context.read<CartProvider>();
      final product = productProvider.products
          .cast<Product?>()
          .firstWhere((p) => p?.id == widget.productId, orElse: () => null);
      if (product != null) {
        cart.syncStockMax(product.id, product.stock);
      }
    });
  }

  void _addToCart(Product product, CartProvider cartProvider) {
    final result = cartProvider.addItem(
      CartItem(
        id: product.id,
        nombre: product.nombre,
        precio: product.precioVenta,
        imagenUrl: product.imagenUrl ?? '',
        stockMax: product.stock > 0 ? product.stock : 0,
        cantidad: 1,
      ),
    );

    String msg;
    Color bg;
    switch (result) {
      case CartAddResult.added:
        msg = '${product.nombre} agregado al carrito';
        bg = const Color(0xFFD4AF37);
        break;
      case CartAddResult.increased:
        msg = 'Cantidad actualizada (máx. ${product.stock})';
        bg = const Color(0xFFD4AF37);
        break;
      case CartAddResult.atLimit:
        msg = 'Solo hay ${product.stock} unidades disponibles';
        bg = Colors.orange.shade800;
        break;
      case CartAddResult.outOfStock:
        msg = 'Producto agotado';
        bg = Colors.red.shade700;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    final Product? product = productProvider.products
        .cast<Product?>()
        .firstWhere((p) => p?.id == widget.productId, orElse: () => null);

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

    final inCart = cartProvider.items.where((i) => i.id == product.id);
    final qtyInCart = inCart.isEmpty ? 0 : inCart.first.cantidad;
    final canAdd = product.stock > 0 && qtyInCart < product.stock;

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
                  Text(
                    product.nombre,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'S/ ${product.precioVenta.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  if (qtyInCart > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'En tu carrito: $qtyInCart / ${product.stock}',
                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Text(
                    'Descripción',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.descripcion ??
                        'No hay descripción disponible para este producto.',
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: canAdd ? () => _addToCart(product, cartProvider) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        product.stock <= 0
                            ? 'Producto agotado'
                            : qtyInCart >= product.stock
                                ? 'Stock máximo en carrito'
                                : 'Agregar al carrito',
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
