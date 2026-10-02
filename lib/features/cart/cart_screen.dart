// lib/features/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/models/product_model.dart';

const _gold = Color(0xFFD4AF37);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pp = context.read<ProductProvider>();
      await pp.loadProducts();
      if (!mounted) return;
      context.read<CartProvider>().syncFromProducts(pp.catalog);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final items = cartProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          IconButton(
            tooltip: 'Dori',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/asistente'),
          ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyState(context)
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
                _buildBottomSummary(context, cartProvider),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Tu carrito está vacío', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          const Text('Agrega productos desde la tienda', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Seguir comprando'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPreview(BuildContext context, CartItem item) async {
    Product? product;
    try {
      product = await context.read<ProductProvider>().getById(item.id);
    } catch (_) {}
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _CartPreview(item: item, product: product),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cartProvider) {
    final atMax = item.cantidad >= item.stockMax;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openPreview(context, item),
                borderRadius: BorderRadius.circular(8),
                child: ClipRRect(
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  if (item.lista > item.precio + 0.009)
                    Text(
                      'S/ ${item.lista.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    'S/ ${item.precio.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (atMax)
                    Text(
                      'No hay más unidades disponibles',
                      style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'S/ ${(item.precio * item.cantidad).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _gold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: item.cantidad <= 1
                      ? 'Mínimo 1. Usa el tacho para quitarlo'
                      : 'Quitar una unidad',
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: item.cantidad <= 1 ? Colors.grey.shade400 : null,
                  ),
                  onPressed: item.cantidad <= 1
                      ? null
                      : () => cartProvider.updateQuantity(item.id, item.cantidad - 1),
                ),
                Text('${item.cantidad}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: atMax ? Colors.grey : null,
                  ),
                  onPressed: atMax
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No hay más unidades disponibles'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.orange.shade800,
                            ),
                          );
                        }
                      : () {
                          final ok = cartProvider.updateQuantity(item.id, item.cantidad + 1);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No hay más unidades disponibles'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
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
    final auth = context.read<AuthProvider>();
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
              Text(
                'Productos (${cartProvider.itemCount})',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'S/ ${cartProvider.listado.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (cartProvider.descuentos > 0.009) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Descuentos * Promoción', style: TextStyle(fontSize: 16)),
                Text(
                  '− S/ ${cartProvider.descuentos.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                'S/ ${cartProvider.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _gold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (!auth.isLoggedIn) {
                  auth.setNextRouteAfterLogin('/entrega');
                  context.push('/login');
                  return;
                }
                context.push('/entrega');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Continuar compra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Seguir comprando'),
          ),
        ],
      ),
    );
  }
}

class _CartPreview extends StatefulWidget {
  final CartItem item;
  final Product? product;
  const _CartPreview({required this.item, required this.product});

  @override
  State<_CartPreview> createState() => _CartPreviewState();
}

class _CartPreviewState extends State<_CartPreview> {
  final _transform = TransformationController();
  Offset _tap = Offset.zero;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.05;
    if (zoomed) {
      _transform.value = Matrix4.identity();
      return;
    }
    const s = 2.2;
    _transform.value = Matrix4.identity()
      ..translate(-_tap.dx * (s - 1), -_tap.dy * (s - 1))
      ..scale(s);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final desc = (widget.product?.descripcion ?? '').trim();
    final h = MediaQuery.sizeOf(context).height;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: h * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: h * 0.34,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: ColoredBox(
                  color: const Color(0xFFF6F1E8),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            return GestureDetector(
                              onDoubleTapDown: (d) => _tap = d.localPosition,
                              onDoubleTap: _toggleZoom,
                              child: InteractiveViewer(
                                transformationController: _transform,
                                minScale: 1,
                                maxScale: 4,
                                child: SizedBox(
                                  width: box.maxWidth,
                                  height: box.maxHeight,
                                  child: CachedNetworkImage(
                                    imageUrl: item.imagenUrl,
                                    fit: BoxFit.contain,
                                    placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator(color: _gold),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, size: 48),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(backgroundColor: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    if (item.lista > item.precio + 0.009)
                      Text(
                        'S/ ${item.lista.toStringAsFixed(2)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.black45,
                        ),
                      ),
                    Text(
                      'S/ ${item.precio.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _gold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'En tu carrito: ${item.cantidad} · S/ ${(item.precio * item.cantidad).toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(desc, style: const TextStyle(height: 1.4)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Pellizca o toca dos veces la foto para acercar',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black87),
                        child: const Text('Seguir en el carrito'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
