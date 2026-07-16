import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/app_router.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/product_provider.dart';   // ← Este es el correcto (core)
import 'core/providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: const EstiloDoradoApp(),
    ),
  );
}

class EstiloDoradoApp extends StatelessWidget {
  const EstiloDoradoApp({super.key});

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