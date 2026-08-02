// lib/core/providers/cart_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CartItem {
  final int id;
  final String nombre;
  final double precio;
  final String imagenUrl;
  final int stockMax;
  int cantidad;

  CartItem({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagenUrl,
    this.stockMax = 99,
    this.cantidad = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'precio': precio,
        'imagenUrl': imagenUrl,
        'stockMax': stockMax,
        'cantidad': cantidad,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
        nombre: j['nombre']?.toString() ?? '',
        precio: double.tryParse(j['precio']?.toString() ?? '0') ?? 0,
        imagenUrl: j['imagenUrl']?.toString() ?? '',
        stockMax: int.tryParse(j['stockMax']?.toString() ?? '99') ?? 99,
        cantidad: int.tryParse(j['cantidad']?.toString() ?? '1') ?? 1,
      );
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int? _userId;

  List<CartItem> get items => List.unmodifiable(_items);

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + (item.precio * item.cantidad));

  double get total => subtotal;

  int get itemCount => _items.fold(0, (s, i) => s + i.cantidad);

  Future<void> bindUser(int? userId) async {
    if (_userId != null && userId == null) {
      await _persist();
      _items.clear();
      _userId = null;
      notifyListeners();
      return;
    }
    if (userId != null && userId != _userId) {
      if (_userId != null) await _persist();
      _userId = userId;
      await _load();
      notifyListeners();
    }
  }

  String get _key =>
      _userId == null ? 'ed_cart_guest' : 'ed_cart_user_$_userId';

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      _items.clear();
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      for (final e in list) {
        _items.add(CartItem.fromJson(Map<String, dynamic>.from(e as Map)));
      }
    } catch (e) {
      debugPrint('cart load error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
      await _storage.write(key: _key, value: raw);
    } catch (e) {
      debugPrint('cart persist error: $e');
    }
  }

  void addItem(CartItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      final cur = _items[index];
      cur.cantidad = (cur.cantidad + item.cantidad).clamp(1, cur.stockMax);
    } else {
      _items.add(CartItem(
        id: item.id,
        nombre: item.nombre,
        precio: item.precio,
        imagenUrl: item.imagenUrl,
        stockMax: item.stockMax,
        cantidad: item.cantidad.clamp(1, item.stockMax),
      ));
    }
    _persist();
    notifyListeners();
  }

  void removeItem(int id) {
    _items.removeWhere((item) => item.id == id);
    _persist();
    notifyListeners();
  }

  void updateQuantity(int id, int cantidad) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final max = _items[index].stockMax;
      if (cantidad < 1) {
        _items.removeAt(index);
      } else {
        _items[index].cantidad = cantidad.clamp(1, max);
      }
      _persist();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _persist();
    notifyListeners();
  }

  void clearCart() => clear();
}
