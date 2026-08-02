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
      id: int.tryParse(
            (json['id_producto'] ?? json['id'])?.toString() ?? '0',
          ) ??
          0,
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      descripcion: json['descripcion']?.toString(),
      precioVenta:
          double.tryParse(json['precio_venta']?.toString() ?? '0') ?? 0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      imagenUrl: (json['imagen_url'] ?? json['imagenUrl'])?.toString(),
      estado: json['estado']?.toString(),
    );
  }
}
