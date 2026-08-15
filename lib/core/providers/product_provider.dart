// lib/core/providers/product_provider.dart
import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  String _search = '';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get search => _search;

  Future<void> loadProducts({String? search, bool resetSearch = false}) async {
    if (resetSearch) {
      _search = '';
    } else if (search != null) {
      _search = search;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.getAllProducts(search: _search.isEmpty ? null : _search);
    } catch (e) {
      _error = e.toString();
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Product?> getById(int id) async {
    final cached = _products.cast<Product?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
    if (cached != null) return cached;
    return _service.getById(id);
  }

  void clearSearch() {
    _search = '';
    loadProducts(search: '');
  }
}
