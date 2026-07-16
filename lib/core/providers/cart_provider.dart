import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CartItem {
  final int id;
  final String nombre;
  final double precio;
  final String imagenUrl;
  int cantidad;

  CartItem({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagenUrl,
    this.cantidad = 1,
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final ApiService _api = ApiService();

  List<CartItem> get items => _items;

  double get total => _items.fold(
        0,
        (sum, item) => sum + (item.precio * item.cantidad),
      );

  void addItem(CartItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index].cantidad++;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(int id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(int id, int cantidad) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].cantidad = cantidad.clamp(1, 99);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // ==================== CREAR PEDIDO ====================
  Future<bool> realizarPedido({
    required String direccion,
    required String metodoPago,
    String? observacion,
  }) async {
    if (_items.isEmpty) return false;

    try {
      final data = {
        "items": _items
            .map((item) => {
                  "id_producto": item.id,
                  "cantidad": item.cantidad,
                })
            .toList(),
        "direccion_entrega": direccion,
        "forma_pago": metodoPago,
        "observacion": observacion ?? "",
        "total": total,
      };

      final response = await _api.post('/pedidos', data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        clear();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al crear pedido: $e');
      return false;
    }
  }
}