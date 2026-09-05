// lib/features/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/models/product_model.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/app_router.dart';
import '../../core/utils/whatsapp.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final _searchCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  String _lastLoc = '/home';
  DateTime? _lastCatalogReset;
  bool _showDoriHint = true;
  Timer? _doriHintTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().loadProducts();
      _showFullCatalog();
      AppRouter.router.routerDelegate.addListener(_onRouteChanged);
      _doriHintTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _showDoriHint = false);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    AppRouter.router.routerDelegate.removeListener(_onRouteChanged);
    AppRouter.routeObserver.unsubscribe(this);
    _searchCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _doriHintTimer?.cancel();
    super.dispose();
  }

  /// Al volver de ficha, carrito o chat: catálogo completo otra vez.
  @override
  void didPopNext() {
    _showFullCatalog();
  }

  void _onRouteChanged() {
    final loc = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    if (loc == '/home' && _lastLoc != '/home') {
      _showFullCatalog();
    }
    _lastLoc = loc;
  }

  void _showFullCatalog() {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastCatalogReset != null &&
        now.difference(_lastCatalogReset!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastCatalogReset = now;
    _searchCtrl.clear();
    _minCtrl.clear();
    _maxCtrl.clear();
    Provider.of<ProductProvider>(context, listen: false).clearSearch();
    setState(() {});
  }

  Future<void> _runSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      _showFullCatalog();
      return;
    }
    Provider.of<ProductProvider>(context, listen: false).setSearch(query);
    setState(() {});
  }

  void _applyPrecio() {
    double? parse(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t);
    }
    Provider.of<ProductProvider>(context, listen: false).setPrecio(
      min: parse(_minCtrl.text),
      max: parse(_maxCtrl.text),
    );
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
            tooltip: 'WhatsApp',
            icon: const Icon(Icons.chat, color: Color(0xFF128C7E)),
            onPressed: () async {
              final ok = await Whatsapp.open('Hola, soy cliente de Estilo Dorado.');
              if (!ok && context.mounted) {
                AppSnackBar.err(context, 'No se pudo abrir WhatsApp');
              }
            },
          ),
          IconButton(
            tooltip: 'Dori, tu asistente',
            icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
            onPressed: () {
              setState(() => _showDoriHint = false);
              context.push('/asistente');
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  AppSnackBar.hide();
                  context.push('/cart');
                },
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
      body: Stack(
        children: [
          RefreshIndicator(
        color: const Color(0xFFD4AF37),
        onRefresh: () => productProvider.loadProducts(search: productProvider.search),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _HeroBanner()),
            SliverToBoxAdapter(
              child: Padding(
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
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  children: ProductProvider.chips.map((c) {
                    final on = productProvider.chip == c ||
                        (c == 'Todos' && productProvider.chip.isEmpty);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: on,
                        selectedColor: const Color(0xFFD4AF37),
                        onSelected: (_) {
                          productProvider.setChip(c);
                          setState(() {});
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: 'Precio min',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _applyPrecio(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _maxCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: 'Precio máx',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _applyPrecio(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: _applyPrecio, child: const Text('Filtrar')),
                  ],
                ),
              ),
            ),
            if (productProvider.search.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Resultados de “${productProvider.search}”',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: _showFullCatalog,
                        child: const Text('Ver todo'),
                      ),
                    ],
                  ),
                ),
              ),
            if (productProvider.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                ),
              )
            else if (productProvider.error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                          onPressed: () => productProvider.loadProducts(resetSearch: true),
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
              )
            else if (productProvider.products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      productProvider.search.isEmpty
                          ? 'No hay productos disponibles'
                          : 'Sin resultados para “${productProvider.search}”',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    TextButton(
                      onPressed: () => productProvider.loadProducts(resetSearch: true),
                      child: const Text('Recargar catálogo'),
                    ),
                    if (productProvider.search.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          productProvider.clearSearch();
                        },
                        child: const Text('Limpiar búsqueda'),
                      ),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = productProvider.products[index];
                      return _buildProductCard(context, product);
                    },
                    childCount: productProvider.products.length,
                  ),
                ),
              ),
          ],
        ),
          ),
          if (_showDoriHint)
            Positioned(
              top: 6,
              right: 52,
              child: _DoriNube(
                onOpen: () {
                  setState(() => _showDoriHint = false);
                  context.push('/asistente');
                },
                onClose: () => setState(() => _showDoriHint = false),
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
                    if (product.enOferta) ...[
                      Text(
                        'S/ ${product.precioLista.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    Text(
                      'S/ ${product.precioVenta.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    Text(
                      product.stock > 0 ? 'Stock ${product.stock}' : 'Agotado',
                      style: TextStyle(
                        fontSize: 12,
                        color: product.stock > 0 ? Colors.green.shade800 : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
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
              _showFullCatalog();
              context.go('/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('Dori'),
            subtitle: const Text('Hola, soy Dori. ¿Te ayudo a elegir un regalo?'),
            onTap: () {
              Navigator.pop(context);
              context.push('/asistente');
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
            title: const Text('WhatsApp'),
            subtitle: const Text('Hablar con la tienda'),
            onTap: () async {
              Navigator.pop(context);
              final ok = await Whatsapp.open('Hola, soy cliente de Estilo Dorado.');
              if (!ok && context.mounted) {
                AppSnackBar.err(context, 'No se pudo abrir WhatsApp');
              }
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
                auth.clearNextRouteAfterLogin();
                context.push('/login');
              },
            ),
        ],
      ),
    );
  }
}

/// Carrusel de portadas (7 s).
class _HeroBanner extends StatefulWidget {
  const _HeroBanner();

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  static const _urls = [
    'https://i.imgur.com/Lz3mumi.png',
    'https://i.imgur.com/bG9AmNv.png',
    'https://i.imgur.com/9b8uchv.png',
  ];

  final _page = PageController();
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || !_page.hasClients) return;
      _i = (_i + 1) % _urls.length;
      _page.animateToPage(
        _i,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final bannerH = (h * 0.30).clamp(168.0, 248.0);

    return SizedBox(
      height: bannerH,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _page,
            itemCount: _urls.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: _urls[i],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFF2D2418)),
              errorWidget: (_, __, ___) => Container(color: const Color(0xFF2D2418)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_urls.length, (i) {
                final on = i == _i;
                return Container(
                  width: on ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: on ? const Color(0xFFD4AF37) : Colors.white70,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoriNube extends StatelessWidget {
  final VoidCallback onOpen;
  final VoidCallback onClose;
  const _DoriNube({required this.onOpen, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: CustomPaint(
                size: const Size(14, 8),
                painter: _NubeFlechaPainter(),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 230),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Hola, soy Dori.\n¿Te ayudo a elegir un regalo?\nDime qué buscas o para quién es.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2418),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close, size: 16, color: Colors.black54),
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

class _NubeFlechaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

