// lib/features/products/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/app_router.dart';
import '../../core/utils/whatsapp.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final productProvider = context.read<ProductProvider>();
    final cart = context.read<CartProvider>();
    try {
      final p = await productProvider.getById(widget.productId);
      if (!mounted) return;
      if (p == null) {
        setState(() {
          _product = null;
          _loading = false;
          _error = 'Producto no encontrado';
        });
        return;
      }
      cart.syncStockMax(p.id, p.stock);
      setState(() {
        _product = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
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
    switch (result) {
      case CartAddResult.added:
        msg = '${product.nombre} agregado al carrito';
        AppSnackBar.ok(
          context,
          msg,
          actionLabel: 'Ver carrito',
          onAction: () => AppRouter.router.push('/cart'),
        );
        return;
      case CartAddResult.increased:
        msg = 'Cantidad actualizada (máx. ${product.stock})';
        AppSnackBar.ok(context, msg);
        return;
      case CartAddResult.atLimit:
        AppSnackBar.warn(context, 'Solo hay ${product.stock} unidades disponibles');
        return;
      case CartAddResult.outOfStock:
        AppSnackBar.err(context, 'Producto agotado');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Producto'),
          backgroundColor: const Color(0xFFD4AF37),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    final product = _product;
    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Producto'),
          backgroundColor: const Color(0xFFD4AF37),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_error ?? 'Este producto no existe', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Volver al catálogo'),
              ),
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
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: canAdd ? () => _addToCart(product, cartProvider) : null,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(canAdd ? 'Agregar al carrito' : 'Sin stock disponible'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await Whatsapp.open(
                          'Hola, quiero consultar por: ${product.nombre}',
                        );
                        if (!ok && context.mounted) {
                          AppSnackBar.err(context, 'No se pudo abrir WhatsApp');
                        }
                      },
                      icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                      label: const Text('Consultar por WhatsApp'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF128C7E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF25D366)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                    child: const Text('← Seguir comprando'),
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
