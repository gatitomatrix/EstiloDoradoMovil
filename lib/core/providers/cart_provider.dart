// lib/core/providers/cart_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CartItem {
  final int id;
  final String nombre;
  final double precio;
  final String imagenUrl;
  int stockMax;
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

  CartItem copyWith({
    int? cantidad,
    int? stockMax,
    String? nombre,
    double? precio,
    String? imagenUrl,
  }) =>
      CartItem(
        id: id,
        nombre: nombre ?? this.nombre,
        precio: precio ?? this.precio,
        imagenUrl: imagenUrl ?? this.imagenUrl,
        stockMax: stockMax ?? this.stockMax,
        cantidad: cantidad ?? this.cantidad,
      );
}

/// Resultado de agregar / actualizar cantidad en carrito (para feedback UI).
enum CartAddResult { added, increased, atLimit, outOfStock }

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int? _userId;
  bool _initialized = false;

  List<CartItem> get items => List.unmodifiable(_items);

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + (item.precio * item.cantidad));

  double get total => subtotal;

  int get itemCount => _items.fold(0, (s, i) => s + i.cantidad);

  static const _guestKey = 'ed_cart_guest';

  String get _key =>
      _userId == null ? _guestKey : 'ed_cart_user_$_userId';

  /// Carga carrito invitado al arrancar (antes de saber si hay sesión).
  Future<void> initGuest() async {
    if (_initialized) return;
    _userId = null;
    await _load();
    _initialized = true;
    notifyListeners();
  }

  /// Asocia carrito al usuario. En login: fusiona guest + user.
  Future<void> bindUser(int? userId) async {
    // Logout: guardar user, vaciar y recargar guest vacío
    if (_userId != null && userId == null) {
      await _persist();
      _items.clear();
      _userId = null;
      await _storage.write(key: _guestKey, value: '[]');
      notifyListeners();
      return;
    }

    // Login o cambio de usuario
    if (userId != null && userId != _userId) {
      // Snapshot de lo que hay ahora (suele ser guest)
      final guestSnapshot = List<CartItem>.from(_items);

      if (_userId != null) {
        await _persist();
      }

      _userId = userId;
      await _load(); // carrito del usuario

      if (guestSnapshot.isNotEmpty) {
        _mergeItems(guestSnapshot);
        await _persist();
        // Limpiar guest para no re-fusionar
        await _storage.write(key: _guestKey, value: '[]');
      }

      notifyListeners();
      return;
    }

    // Primera carga sin usuario
    if (userId == null && !_initialized) {
      await initGuest();
    }
  }

  void _mergeItems(List<CartItem> extra) {
    for (final g in extra) {
      final idx = _items.indexWhere((i) => i.id == g.id);
      final max = (g.stockMax > 0 ? g.stockMax : 99);
      if (idx < 0) {
        _items.add(CartItem(
          id: g.id,
          nombre: g.nombre,
          precio: g.precio,
          imagenUrl: g.imagenUrl,
          stockMax: max,
          cantidad: g.cantidad.clamp(1, max),
        ));
      } else {
        final cur = _items[idx];
        final m = cur.stockMax > 0 ? cur.stockMax : max;
        cur.stockMax = m;
        cur.cantidad = (cur.cantidad + g.cantidad).clamp(1, m);
        if (g.nombre.isNotEmpty) {
          // keep product info freshest
        }
      }
    }
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      _items.clear();
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      for (final e in list) {
        final item = CartItem.fromJson(Map<String, dynamic>.from(e as Map));
        final max = item.stockMax < 1 ? 1 : item.stockMax;
        item.stockMax = max;
        item.cantidad = item.cantidad.clamp(1, max);
        _items.add(item);
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

  void syncStockMax(int productId, int stockMax) {
    final index = _items.indexWhere((i) => i.id == productId);
    if (index < 0) return;
    final max = stockMax < 1 ? 1 : stockMax;
    final cur = _items[index];
    if (cur.stockMax == max && cur.cantidad <= max) return;
    cur.stockMax = max;
    if (cur.cantidad > max) cur.cantidad = max;
    _persist();
    notifyListeners();
  }

  void syncStocks(Map<int, int> stockById) {
    var changed = false;
    for (final item in _items) {
      final s = stockById[item.id];
      if (s == null) continue;
      final max = s < 1 ? 1 : s;
      if (item.stockMax != max || item.cantidad > max) {
        item.stockMax = max;
        if (item.cantidad > max) item.cantidad = max;
        changed = true;
      }
    }
    if (changed) {
      _persist();
      notifyListeners();
    }
  }

  CartAddResult addItem(CartItem item) {
    final max = item.stockMax < 1 ? 0 : item.stockMax;
    if (max < 1) return CartAddResult.outOfStock;

    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      final cur = _items[index];
      cur.stockMax = max;
      if (cur.cantidad >= max) {
        cur.cantidad = max;
        _persist();
        notifyListeners();
        return CartAddResult.atLimit;
      }
      final next = (cur.cantidad + item.cantidad).clamp(1, max);
      final atLimit = next >= max && cur.cantidad + item.cantidad > max;
      cur.cantidad = next;
      _persist();
      notifyListeners();
      return atLimit ? CartAddResult.atLimit : CartAddResult.increased;
    }

    final qty = item.cantidad.clamp(1, max);
    _items.add(CartItem(
      id: item.id,
      nombre: item.nombre,
      precio: item.precio,
      imagenUrl: item.imagenUrl,
      stockMax: max,
      cantidad: qty,
    ));
    _persist();
    notifyListeners();
    return qty < item.cantidad ? CartAddResult.atLimit : CartAddResult.added;
  }

  void removeItem(int id) {
    _items.removeWhere((item) => item.id == id);
    _persist();
    notifyListeners();
  }

  bool updateQuantity(int id, int cantidad) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    final max = _items[index].stockMax < 1 ? 1 : _items[index].stockMax;
    if (cantidad < 1) {
      // El tacho elimina el producto; − no baja de 1.
      return false;
    }
    if (cantidad > max) {
      _items[index].cantidad = max;
      _persist();
      notifyListeners();
      return false;
    }
    _items[index].cantidad = cantidad;
    _persist();
    notifyListeners();
    return true;
  }

  void clear() {
    _items.clear();
    _persist();
    notifyListeners();
  }

  void clearCart() => clear();
}
