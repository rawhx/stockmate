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
  bool _isSaving = false;
  bool _disposed = false;
  int _generation = 0;
  String? _ownerId;
  bool _hasOwner = false;
  String? _errorMessage;
  Future<void>? _pendingFetch;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
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
    _isSaving = false;
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

  Future<bool> addProduct(Product product) =>
      _mutate(() => _createProduct(product));
  Future<bool> editProduct(Product product) =>
      _mutate(() => _updateProduct(product));

  Future<int> changeProductCategory(
    Set<String> productIds,
    String categoryId,
  ) async {
    if (productIds.isEmpty) return 0;
    final generation = _generation;
    final ids = productIds.toList();
    const batchSize = 100;
    final moved = <String>{};
    String? failure;
    final success = await _mutate(() async {
      for (var offset = 0; offset < ids.length; offset += batchSize) {
        if (!_isCurrent(generation)) return;
        try {
          final batch = ids.skip(offset).take(batchSize).toSet();
          moved.addAll(await _updateProduct.changeCategory(batch, categoryId));
        } catch (error) {
          // Preserve results from batches that committed before a failure.
          failure = _message(error);
          break;
        }
      }
      if (moved.isEmpty && failure != null) throw StateError(failure!);
    });
    return success ? moved.length : 0;
  }

  Future<bool> removeProduct(String id) {
    final generation = _generation;
    return _mutate(() async {
      await _deleteProduct(id);
      if (_isCurrent(generation)) {
        _products = _products.where((product) => product.id != id).toList();
      }
    });
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    if (_isSaving || _disposed) return false;
    final generation = _generation;
    _isSaving = true;
    _errorMessage = null;
    _notify();
    try {
      await action();
      if (!_isCurrent(generation)) return false;
      final pending = _pendingFetch;
      if (pending != null) await pending;
      if (!_isCurrent(generation)) return false;
      // A read failure after a committed write must not invite a duplicate save.
      await fetchProducts();
      return _isCurrent(generation);
    } catch (error) {
      if (_isCurrent(generation)) _errorMessage = _message(error);
      return false;
    } finally {
      if (_isCurrent(generation)) {
        _isSaving = false;
        _notify();
      }
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
