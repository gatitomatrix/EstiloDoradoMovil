// lib/core/providers/product_provider.dart
import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> _all = [];
  bool _isLoading = false;
  String? _error;
  String _search = '';
  String _chip = 'Todos';
  double? precioMin;
  double? precioMax;

  static const chips = [
    'Todos',
    'Amor',
    'Para Él',
    'Para Ella',
    'Cumpleaños',
    'Tendencias',
    'Peluches',
  ];

  static const chipKeys = {
    'Amor': ['romance', 'pareja', 'enamorados'],
    'Para Él': ['caballero', 'hombre', 'cerveza', 'billetera', 'futbol', 'deporte'],
    'Para Ella': ['bolso', 'moda', 'perfume', 'fragancia', 'rosa'],
    'Cumpleaños': ['cumpleaños', 'fiesta', 'globos'],
    'Tendencias': ['stich', 'hotwheels', 'piton', 'cerdita'],
    'Peluches': ['peluche', 'osito', 'stich', 'cerdita', 'infantil'],
  };

  List<Product> get products {
    var list = List<Product>.from(_all);
    if (_search.isNotEmpty) {
      list = list.where((p) => p.matches(_search)).toList();
    }
    if (_chip.isNotEmpty && _chip != 'Todos') {
      final keys = chipKeys[_chip] ?? [_chip.toLowerCase()];
      list = list.where((p) => keys.any((k) => p.haystack.contains(k.toLowerCase()))).toList();
    }
    if (precioMin != null) {
      list = list.where((p) => p.precioVenta >= precioMin!).toList();
    }
    if (precioMax != null) {
      list = list.where((p) => p.precioVenta <= precioMax!).toList();
    }
    return list;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get search => _search;
  String get chip => _chip;

  Future<void> loadProducts({String? search, bool resetSearch = false}) async {
    if (resetSearch) {
      _search = '';
      _chip = 'Todos';
      precioMin = null;
      precioMax = null;
    } else if (search != null) {
      _search = search;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _all = await _service.getAllProducts();
    } catch (e) {
      _error = e.toString();
      _all = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String q) {
    _search = q.trim();
    notifyListeners();
  }

  void setChip(String c) {
    _chip = c;
    notifyListeners();
  }

  void setPrecio({double? min, double? max}) {
    precioMin = min;
    precioMax = max;
    notifyListeners();
  }

  Future<Product?> getById(int id) async {
    final cached = _all.cast<Product?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
    if (cached != null) return cached;
    return _service.getById(id);
  }

  void clearSearch() {
    _search = '';
    _chip = 'Todos';
    precioMin = null;
    precioMax = null;
    if (_all.isEmpty) {
      loadProducts();
    } else {
      notifyListeners();
    }
  }
}
