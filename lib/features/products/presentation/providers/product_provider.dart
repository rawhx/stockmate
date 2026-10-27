import 'package:flutter/foundation.dart';

import '../../domain/entities/product.dart';
import '../../domain/usecases/create_product.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/get_product.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/usecases/update_product.dart';

class ProductProvider extends ChangeNotifier {
  factory ProductProvider({
    required GetProducts getProducts,
    required GetProduct getProduct,
    required CreateProduct createProduct,
    required UpdateProduct updateProduct,
    required DeleteProduct deleteProduct,
  }) {
    return ProductProvider._(
      getProducts,
      getProduct,
      createProduct,
      updateProduct,
      deleteProduct,
    );
  }

  ProductProvider._(
    this._getProducts,
    this._getProduct,
    this._createProduct,
    this._updateProduct,
    this._deleteProduct,
  );

  final GetProducts _getProducts;
  final GetProduct _getProduct;
  final CreateProduct _createProduct;
  final UpdateProduct _updateProduct;
  final DeleteProduct _deleteProduct;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => List.unmodifiable(_products);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts() async {
    _setLoading(true);

    try {
      _products = await _getProducts();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Product?> getProductById(String id) {
    return _getProduct(id);
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
