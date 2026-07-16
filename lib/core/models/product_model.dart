// lib/core/models/product_model.dart
class Product {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precioVenta;
  final int stock;
  final String? imagenUrl;
  final String? estado;

  Product({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precioVenta,
    required this.stock,
    this.imagenUrl,
    this.estado,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id_producto'] ?? json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      descripcion: json['descripcion'],
      precioVenta: double.tryParse(json['precio_venta']?.toString() ?? '0') ?? 0.0,
      stock: json['stock'] ?? 0,
      imagenUrl: json['imagen_url'],
      estado: json['estado'],
    );
  }
}