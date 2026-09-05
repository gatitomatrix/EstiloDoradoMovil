// lib/core/models/product_model.dart
class Product {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? etiquetas;
  final double precioVenta;
  final double precioLista;
  final int stock;
  final String? imagenUrl;
  final String? estado;

  Product({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.etiquetas,
    required this.precioVenta,
    required this.precioLista,
    required this.stock,
    this.imagenUrl,
    this.estado,
  });

  bool get enOferta => precioLista > precioVenta + 0.009;

  String get haystack =>
      '${nombre} ${descripcion ?? ''} ${etiquetas ?? ''}'.toLowerCase();

  bool matches(String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return true;
    return haystack.contains(t);
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final lista =
        double.tryParse((json['precio_venta'] ?? json['precio'])?.toString() ?? '0') ?? 0.0;
    final fin = double.tryParse(
          (json['precio_final'] ?? json['precio_venta'] ?? json['precio'])?.toString() ?? '0',
        ) ??
        lista;
    return Product(
      id: int.tryParse(
            (json['id_producto'] ?? json['id'])?.toString() ?? '0',
          ) ??
          0,
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      descripcion: json['descripcion']?.toString(),
      etiquetas: json['etiquetas']?.toString(),
      precioVenta: fin,
      precioLista: lista > 0 ? lista : fin,
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      imagenUrl: (json['imagen_url'] ?? json['imagenUrl'])?.toString(),
      estado: json['estado']?.toString(),
    );
  }
}
