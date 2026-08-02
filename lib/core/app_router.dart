// lib/core/app_router.dart
// App móvil = cliente (tienda). El panel admin vive en la web (Angular), según alcance del proyecto.
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../core/models/checkout_models.dart';

// Cliente
import '../features/home/home_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/entrega_screen.dart';
import '../features/checkout/confirmar_entrega_screen.dart';
import '../features/checkout/pago_screen.dart';
import '../features/orders/mis_compras_screen.dart';
import '../features/orders/resumen_pedido_screen.dart';
import '../features/orders/pagar_pedido_screen.dart';
import '../features/orders/views/order_success_screen.dart';
import '../features/payment/culqi_payment_screen.dart';
import '../features/account/mi_cuenta_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isLoggedIn;
      final loc = state.matchedLocation;

      // Admin no forma parte de la app móvil (alcance: panel web)
      if (loc.startsWith('/admin')) {
        return '/home';
      }

      final protectedRoutes = [
        '/entrega',
        '/confirmar-entrega',
        '/pago',
        '/mis-compras',
        '/mi-cuenta',
        '/order-success',
      ];

      final needsAuth = protectedRoutes.contains(loc) ||
          loc.startsWith('/resumen/') ||
          loc.startsWith('/pagar-pedido/') ||
          loc.startsWith('/culqi-payment');

      if (needsAuth && !isLoggedIn) {
        authProvider.setNextRouteAfterLogin(state.uri.toString());
        return '/login';
      }

      if (loc == '/login' && isLoggedIn) {
        final nextRoute = authProvider.nextRouteAfterLogin;
        if (nextRoute != null) {
          authProvider.clearNextRouteAfterLogin();
          // No redirigir a admin si quedó en memoria de sesiones viejas
          if (nextRoute.startsWith('/admin')) {
            return '/home';
          }
          return nextRoute;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/recuperar', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/mi-cuenta', builder: (context, state) => const MiCuentaScreen()),
      GoRoute(
        path: '/producto/:id',
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),

      // Flujo de compra (cliente)
      GoRoute(path: '/entrega', builder: (context, state) => const EntregaScreen()),
      GoRoute(
        path: '/confirmar-entrega',
        builder: (context, state) => const ConfirmarEntregaScreen(),
      ),
      GoRoute(path: '/pago', builder: (context, state) => const PagoScreen()),
      GoRoute(
        path: '/resumen/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          ComprobanteOut? comp;
          if (extra['comprobante'] is ComprobanteOut) {
            comp = extra['comprobante'] as ComprobanteOut;
          }
          return ResumenPedidoScreen(
            pedidoId: id,
            ventaOk: extra['ventaOk'] == true,
            comprobanteExtra: comp,
          );
        },
      ),
      GoRoute(
        path: '/pagar-pedido/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return PagarPedidoScreen(
            pedidoId: id,
            total: (extra['total'] as num?)?.toDouble() ?? 0,
            formaPagoSugerida: extra['formaPago']?.toString(),
          );
        },
      ),
      GoRoute(path: '/mis-compras', builder: (context, state) => const MisComprasScreen()),
      GoRoute(
        path: '/checkout',
        redirect: (context, state) => '/entrega',
      ),
      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          ComprobanteOut? comp;
          if (extra['comprobante'] is ComprobanteOut) {
            comp = extra['comprobante'] as ComprobanteOut;
          }
          return OrderSuccessScreen(
            metodoPago: extra['metodoPago']?.toString() ?? 'yape',
            total: (extra['total'] as num?)?.toDouble() ?? 0.0,
            pedidoId: extra['pedidoId'] as int? ?? 0,
            comprobante: comp,
            sunatPdf: extra['sunatPdf']?.toString(),
            sunatXml: extra['sunatXml']?.toString(),
            sunatCdr: extra['sunatCdr']?.toString(),
          );
        },
      ),
      GoRoute(
        path: '/culqi-payment',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return CulqiPaymentScreen(
            pedidoId: extra['pedidoId'] as int? ?? 0,
            total: (extra['total'] as num?)?.toDouble() ?? 0.0,
          );
        },
      ),

      GoRoute(path: '/', redirect: (context, state) => '/home'),
    ],
  );
}
