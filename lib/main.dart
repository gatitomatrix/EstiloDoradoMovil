// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/app_router.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/product_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/checkout_provider.dart';
import 'core/providers/payment_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider();
            auth.checkAuth();
            return auth;
          },
        ),
        ChangeNotifierProvider(create: (_) {
          final cart = CartProvider();
          cart.initGuest();
          return cart;
        }),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: const EstiloDoradoApp(),
    ),
  );
}

class EstiloDoradoApp extends StatefulWidget {
  const EstiloDoradoApp({super.key});

  @override
  State<EstiloDoradoApp> createState() => _EstiloDoradoAppState();
}

class _EstiloDoradoAppState extends State<EstiloDoradoApp> {
  AuthProvider? _auth;
  bool _listening = false;
  bool _syncing = false;

  Future<void> _syncCart() async {
    if (!mounted || _syncing) return;
    _syncing = true;
    try {
      final auth = context.read<AuthProvider>();
      final cart = context.read<CartProvider>();
      final uid = auth.user?['id_cliente'];
      final id = uid is int ? uid : int.tryParse(uid?.toString() ?? '');
      await cart.bindUser(auth.isLoggedIn ? id : null);
    } finally {
      _syncing = false;
    }
  }

  void _onAuthChanged() {
    _syncCart();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _auth = context.read<AuthProvider>();
      _auth!.addListener(_onAuthChanged);
      _listening = true;
      _syncCart();
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Estilo Dorado',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
