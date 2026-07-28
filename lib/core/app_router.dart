// lib/core/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Providers
import '../core/providers/auth_provider.dart';

// Pantallas Cliente
import '../features/home/home_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/orders/mis_compras_screen.dart';
import '../features/orders/views/order_success_screen.dart';
import '../features/payment/culqi_payment_screen.dart';

// Pantallas Admin
import '../features/admin/auth/admin_login_screen.dart';
import '../features/admin/dashboard/admin_dashboard_screen.dart';
import '../features/admin/productos/admin_productos_screen.dart';
import '../features/admin/pedidos/admin_pedidos_screen.dart';
import '../features/admin/clientes/admin_clientes_screen.dart';
import '../features/admin/inventario/admin_inventario_screen.dart';
import '../features/admin/reportes/admin_reportes_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isLoggedIn;
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      // Rutas protegidas que requieren login del cliente
      final protectedRoutes = ['/checkout', '/mis-compras'];

      // 1. Si quiere ir a una ruta protegida y NO está logueado
      if (protectedRoutes.contains(state.matchedLocation) && !isLoggedIn) {
        authProvider.setNextRouteAfterLogin(state.matchedLocation);
        return '/login';
      }

      // 2. Si acaba de hacer login correctamente y tenemos una ruta guardada
      if (state.matchedLocation == '/login' && isLoggedIn) {
        final nextRoute = authProvider.nextRouteAfterLogin;
        if (nextRoute != null) {
          authProvider.clearNextRouteAfterLogin();
          return nextRoute;
        }
      }

      // 3. Admin routes
      if (isAdminRoute && !isLoggedIn) {
        return '/admin/login';
      }

      return null; // sin redirección
    },
    routes: [
      // ====================== RUTAS CLIENTE ======================
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

      // Detalle de producto
      GoRoute(
        path: '/producto/:id',
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: productId);
        },
      ),

      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
      GoRoute(path: '/mis-compras', builder: (context, state) => const MisComprasScreen()),

      // ====================== RUTA DE ÉXITO ======================
      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OrderSuccessScreen(
            metodoPago: extra['metodoPago'] as String? ?? 'yape',
            total: extra['total'] as double? ?? 0.0,
            pedidoId: extra['pedidoId'] as int? ?? 0,
          );
        },
      ),

      // ====================== RUTA DE PAGO CULQI ======================
      GoRoute(
        path: '/culqi-payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CulqiPaymentScreen(
            pedidoId: extra['pedidoId'] as int? ?? 0,
            total: extra['total'] as double? ?? 0.0,
          );
        },
      ),

      // ====================== RUTAS ADMIN ======================
      GoRoute(path: '/admin/login', builder: (context, state) => const AdminLoginScreen()),
      GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/productos', builder: (context, state) => const AdminProductosScreen()),
      GoRoute(path: '/admin/pedidos', builder: (context, state) => const AdminPedidosScreen()),
      GoRoute(path: '/admin/clientes', builder: (context, state) => const AdminClientesScreen()),
      GoRoute(path: '/admin/inventario', builder: (context, state) => const AdminInventarioScreen()),
      GoRoute(path: '/admin/reportes', builder: (context, state) => const AdminReportesScreen()),

      // Ruta por defecto
      GoRoute(path: '/', redirect: (context, state) => '/home'),
    ],
  );
}