// lib/features/admin/reportes/admin_reportes_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class AdminReportesScreen extends StatefulWidget {
  const AdminReportesScreen({super.key});

  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic> _estadisticas = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    try {
      final response = await _api.get('/admin/reportes/dashboard');
      setState(() {
        _estadisticas = response.data ?? {};
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando reportes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Estadísticas'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarReportes,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumen General', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    _buildStatCard('Total Ventas', 'S/ ${_estadisticas['total_ventas']?.toString() ?? '0.00'}', Icons.attach_money, Colors.green),
                    _buildStatCard('Pedidos Hoy', '${_estadisticas['pedidos_hoy'] ?? 0}', Icons.shopping_cart, Colors.orange),
                    _buildStatCard('Productos Activos', '${_estadisticas['productos_activos'] ?? 0}', Icons.inventory, Colors.blue),
                    _buildStatCard('Clientes Registrados', '${_estadisticas['clientes_total'] ?? 0}', Icons.people, Colors.purple),

                    const SizedBox(height: 32),
                    const Text('Acciones Rápidas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: () => _descargarReporte('ventas'),
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar Reporte de Ventas'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _descargarReporte('inventario'),
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar Reporte de Inventario'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 40, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  void _descargarReporte(String tipo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Descargando reporte de $tipo... (Próximamente)')),
    );
  }
}