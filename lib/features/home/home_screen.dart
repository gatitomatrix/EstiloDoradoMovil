// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/models/product_model.dart';
import '../../core/utils/app_snackbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    await Provider.of<ProductProvider>(context, listen: false).loadProducts(search: q.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estilo Dorado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD4AF37),
        actions: [
          IconButton(
            tooltip: 'Asistente IA',
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () => context.push('/asistente'),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => context.push('/cart'),
              ),
              if (cartProvider.items.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${cartProvider.items.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, authProvider),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: _runSearch,
              decoration: InputDecoration(
                hintText: 'Buscar productos…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                          productProvider.clearSearch();
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _runSearch(_searchCtrl.text),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE7DAC6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE7DAC6)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => productProvider.loadProducts(search: productProvider.search),
              child: productProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    )
                  : productProvider.error != null
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No se pudieron cargar productos.\nRevisa Laravel en local.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: () => productProvider.loadProducts(),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFD4AF37),
                                        foregroundColor: Colors.black87,
                                      ),
                                      child: const Text('Reintentar'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : productProvider.products.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 60),
                                Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  productProvider.search.isEmpty
                                      ? 'No hay productos disponibles'
                                      : 'Sin resultados para “${productProvider.search}”',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (productProvider.search.isNotEmpty)
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        productProvider.clearSearch();
                                      },
                                      child: const Text('Limpiar búsqueda'),
                                    ),
                                  ),
                              ],
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: productProvider.products.length,
                              itemBuilder: (context, index) {
                                final product = productProvider.products[index];
                                return _buildProductCard(context, product);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => context.push('/producto/${product.id}'),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.05,
              child: Hero(
                tag: 'product-${product.id}',
                child: CachedNetworkImage(
                  imageUrl: product.imagenUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 70),
                  ),
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S/ ${product.precioVenta.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
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

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    final isLoggedIn = auth.isLoggedIn;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFD4AF37)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Text(
                  'Estilo Dorado',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoggedIn
                      ? (auth.user?['nombre']?.toString() ?? 'Usuario')
                      : 'Invitado',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              context.go('/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('Asistente IA'),
            subtitle: const Text('Preguntas sobre productos y pedidos'),
            onTap: () {
              Navigator.pop(context);
              context.push('/asistente');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Carrito'),
            onTap: () {
              Navigator.pop(context);
              context.push('/cart');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Mis compras'),
            onTap: () {
              Navigator.pop(context);
              if (isLoggedIn) {
                context.push('/mis-compras');
              } else {
                auth.setNextRouteAfterLogin('/mis-compras');
                context.push('/login');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi cuenta'),
            onTap: () {
              Navigator.pop(context);
              if (isLoggedIn) {
                context.push('/mi-cuenta');
              } else {
                auth.setNextRouteAfterLogin('/mi-cuenta');
                context.push('/login');
              }
            },
          ),
          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.pop(context);
                await auth.logout();
                if (context.mounted) {
                  AppSnackBar.ok(context, 'Sesión cerrada');
                  context.go('/home');
                }
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Iniciar sesión'),
              onTap: () {
                Navigator.pop(context);
                context.push('/login');
              },
            ),
        ],
      ),
    );
  }
}
