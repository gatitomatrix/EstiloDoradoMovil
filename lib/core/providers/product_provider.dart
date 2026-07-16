// lib/core/providers/product_provider.dart
import 'package:flutter/material.dart';
import '../services/product_service.dart';   // ← Este import es clave
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.getAllProducts(search: search);
    } catch (e) {
      _error = e.toString();
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}