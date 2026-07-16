// lib/features/admin/dashboard/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: const Color(0xFFD4AF37),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actualizando dashboard...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/admin/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenido al Panel',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Estilo Dorado - Administración',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Tarjetas principales
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.05,
              children: [
                _buildDashboardCard(
                  context,
                  icon: Icons.inventory_2_outlined,
                  title: 'Productos',
                  subtitle: '90 total',
                  color: Colors.blue,
                  onTap: () => context.push('/admin/productos'),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  title: 'Pedidos',
                  subtitle: 'Pendientes',
                  color: Colors.orange,
                  onTap: () => context.push('/admin/pedidos'),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.people_outline,
                  title: 'Clientes',
                  subtitle: 'Registrados',
                  color: Colors.green,
                  onTap: () => context.push('/admin/clientes'),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.warehouse_outlined,
                  title: 'Inventario',
                  subtitle: 'Movimientos',
                  color: Colors.purple,
                  onTap: () => context.push('/admin/inventario'),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Reportes',
                  subtitle: 'Estadísticas',
                  color: Colors.teal,
                  onTap: () => context.push('/admin/reportes'),
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Configuración',
                  subtitle: 'Sistema',
                  color: Colors.grey,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Configuración - Próximamente')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 52, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}