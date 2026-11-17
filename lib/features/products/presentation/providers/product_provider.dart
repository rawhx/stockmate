import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/product_form_options.dart';
import '../../domain/usecases/create_product.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/get_product.dart';
import '../../domain/usecases/get_product_form_options.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/usecases/update_product.dart';

class ProductProvider extends ChangeNotifier {
  factory ProductProvider({
    required GetProducts getProducts,
    required GetProduct getProduct,
    required GetProductFormOptions getFormOptions,
    required CreateProduct createProduct,
    required UpdateProduct updateProduct,
    required DeleteProduct deleteProduct,
  }) => ProductProvider._(
    getProducts,
    getProduct,
    getFormOptions,
    createProduct,
    updateProduct,
    deleteProduct,
  );

  ProductProvider._(
    this._getProducts,
    this._getProduct,
    this._getFormOptions,
    this._createProduct,
    this._updateProduct,
    this._deleteProduct,
  );

  final GetProducts _getProducts;
  final GetProduct _getProduct;
  final GetProductFormOptions _getFormOptions;
  final CreateProduct _createProduct;
  final UpdateProduct _updateProduct;
  final DeleteProduct _deleteProduct;

  List<Product> _products = [];
  bool _isLoading = false;
  bool _disposed = false;
  int _generation = 0;
  String? _ownerId;
  bool _hasOwner = false;
  String? _errorMessage;
  Future<void>? _pendingFetch;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Invalidate outstanding requests as well as visible data across accounts.
  void setOwner(String? ownerId) {
    if (_hasOwner && ownerId == _ownerId) return;
    _hasOwner = true;
    _ownerId = ownerId;
    _generation++;
    _products = [];
    _errorMessage = null;
    _pendingFetch = null;
    _isLoading = false;
    _notify();
    if (ownerId != null) {
      final generation = _generation;
      scheduleMicrotask(() {
        if (_isCurrent(generation)) unawaited(fetchProducts());
      });
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<void> fetchProducts() {
    if (_pendingFetch != null) return _pendingFetch!;
    final request = _fetchProducts(_generation);
    _pendingFetch = request;
    return request.whenComplete(() {
      if (identical(_pendingFetch, request)) _pendingFetch = null;
    });
  }

  Future<void> _fetchProducts(int generation) async {
    _isLoading = true;
    _notify();
    try {
      final products = await _getProducts();
      if (!_isCurrent(generation)) return;
      _products = products;
      _errorMessage = null;
    } catch (error) {
      if (_isCurrent(generation)) _errorMessage = _message(error);
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<Product?> getProductById(String id) async {
    final generation = _generation;
    final product = await _getProduct(id);
    return _isCurrent(generation) ? product : null;
  }

  Future<ProductFormOptions> getFormOptions() async {
    final generation = _generation;
    final options = await _getFormOptions();
    if (!_isCurrent(generation)) {
      throw StateError('Akun telah berubah. Muat ulang form.');
    }
    return options;
  }

  Future<bool> addProduct(Product product) async {
    try {
      await _createProduct(product);
      await fetchProducts();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editProduct(Product product) async {
    try {
      await _updateProduct(product);
      await fetchProducts();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeProduct(String id) async {
    try {
      await _deleteProduct(id);
      await fetchProducts();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  String _message(Object error) =>
      error is StateError ? error.message : error.toString();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
