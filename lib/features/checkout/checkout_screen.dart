// Compat: redirige al nuevo flujo de entrega (Fase 1)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/entrega');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
