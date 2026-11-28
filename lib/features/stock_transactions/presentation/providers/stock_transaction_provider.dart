import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';

import '../../domain/entities/stock_transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/usecases/create_stock_transaction.dart';
import '../../domain/usecases/delete_stock_transaction.dart';
import '../../domain/usecases/get_stock_transaction.dart';
import '../../domain/usecases/get_stock_transactions.dart';
import '../../domain/usecases/update_stock_transaction.dart';

enum TransactionFilter { all, inStock, outStock }

class StockTransactionProvider extends ChangeNotifier {
  StockTransactionProvider({
    required this.getStockTransactions,
    required this.getStockTransaction,
    required this.createStockTransaction,
    required this.updateStockTransaction,
    required this.deleteStockTransaction,
    this.onGetProduct,
    this.onUpdateProduct,
    this.onRefreshProducts,
  });

  final GetStockTransactions getStockTransactions;
  final GetStockTransaction getStockTransaction;
  final CreateStockTransaction createStockTransaction;
  final UpdateStockTransaction updateStockTransaction;
  final DeleteStockTransaction deleteStockTransaction;

  Future<Product?> Function(String productId)? onGetProduct;
  Future<bool> Function(Product product)? onUpdateProduct;
  Future<void> Function()? onRefreshProducts;

  List<StockTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  TransactionFilter _currentFilter = TransactionFilter.all;
  String _searchQuery = '';

  String? _ownerId;
  bool _hasOwner = false;
  bool _disposed = false;
  int _generation = 0;
  Future<void>? _pendingFetch;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<StockTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TransactionFilter get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;

  int get totalInStockCount => _transactions
      .where((tx) => tx.type == TransactionType.inStock)
      .fold(0, (sum, tx) => sum + tx.quantity);

  int get totalOutStockCount => _transactions
      .where((tx) => tx.type == TransactionType.outStock)
      .fold(0, (sum, tx) => sum + tx.quantity);

  List<StockTransaction> get filteredTransactions {
    return _transactions.where((tx) {
      final matchesFilter = switch (_currentFilter) {
        TransactionFilter.all => true,
        TransactionFilter.inStock => tx.type == TransactionType.inStock,
        TransactionFilter.outStock => tx.type == TransactionType.outStock,
      };

      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          tx.productName.toLowerCase().contains(query) ||
          tx.productCode.toLowerCase().contains(query) ||
          (tx.notes?.toLowerCase().contains(query) ?? false);

      return matchesFilter && matchesQuery;
    }).toList();
  }

  void setFilter(TransactionFilter filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setOwner(String? ownerId) {
    if (_hasOwner && ownerId == _ownerId) return;
    _hasOwner = true;
    _ownerId = ownerId;
    _generation++;
    _transactions = [];
    _errorMessage = null;
    _pendingFetch = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTransactions() {
    if (_pendingFetch != null) return _pendingFetch!;
    final request = _fetchTransactions(_generation);
    _pendingFetch = request;
    return request.whenComplete(() {
      if (identical(_pendingFetch, request)) _pendingFetch = null;
    });
  }

  Future<void> _fetchTransactions(int gen) async {
    _setLoading(true);
    try {
      final items = await getStockTransactions();
      if (!_disposed && gen == _generation) {
        _transactions = items;
        _errorMessage = null;
      }
    } catch (e) {
      if (!_disposed && gen == _generation) {
        _errorMessage = e.toString().replaceFirst('StateError: ', '');
      }
    } finally {
      if (!_disposed && gen == _generation) {
        _setLoading(false);
      }
    }
  }

  Future<StockTransaction?> getTransactionById(String id) async {
    try {
      return await getStockTransaction(id);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('StateError: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> addTransaction(StockTransaction transaction) async {
    _setLoading(true);
    try {
      if (onGetProduct != null) {
        final product = await onGetProduct!(transaction.productId);
        if (product != null) {
          if (transaction.type == TransactionType.outStock &&
              product.currentStock < transaction.quantity) {
            throw StateError(
              'Stok tidak mencukupi (Tersedia: ${product.currentStock}, Diminta: ${transaction.quantity})',
            );
          }

          if (onUpdateProduct != null) {
            final newStock = transaction.type == TransactionType.inStock
                ? product.currentStock + transaction.quantity
                : product.currentStock - transaction.quantity;
            await onUpdateProduct!(product.copyWith(currentStock: newStock));
          }
        }
      }

      await createStockTransaction(transaction);
      if (onRefreshProducts != null) {
        await onRefreshProducts!();
      }
      await fetchTransactions();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('StateError: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> editTransaction(StockTransaction updated) async {
    _setLoading(true);
    try {
      final old = await getStockTransaction(updated.id);
      if (old == null) {
        throw StateError('Transaksi lama tidak ditemukan.');
      }

      if (onGetProduct != null) {
        final product = await onGetProduct!(updated.productId);
        if (product != null) {
          var simulatedStock = product.currentStock;
          if (old.type == TransactionType.inStock) {
            simulatedStock -= old.quantity;
          } else {
            simulatedStock += old.quantity;
          }

          if (updated.type == TransactionType.outStock &&
              simulatedStock < updated.quantity) {
            throw StateError(
              'Stok tidak mencukupi untuk pembaruan transaksi (Stok efektif: $simulatedStock, Diminta: ${updated.quantity})',
            );
          }

          final finalStock = updated.type == TransactionType.inStock
              ? simulatedStock + updated.quantity
              : simulatedStock - updated.quantity;

          if (finalStock < 0) {
            throw StateError(
              'Pembaruan transaksi menyebabkan stok menjadi negatif.',
            );
          }

          if (onUpdateProduct != null) {
            await onUpdateProduct!(product.copyWith(currentStock: finalStock));
          }
        }
      }

      await updateStockTransaction(updated);
      if (onRefreshProducts != null) {
        await onRefreshProducts!();
      }
      await fetchTransactions();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('StateError: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeTransaction(String id) async {
    _setLoading(true);
    try {
      final existing = await getStockTransaction(id);
      if (existing == null) {
        throw StateError('Transaksi tidak ditemukan');
      }

      if (onGetProduct != null) {
        final product = await onGetProduct!(existing.productId);
        if (product != null) {
          final newStock = existing.type == TransactionType.inStock
              ? product.currentStock - existing.quantity
              : product.currentStock + existing.quantity;

          if (newStock < 0) {
            throw StateError(
              'Tidak dapat menghapus transaksi masuk ini karena stok barang sudah terpakai dan akan bernilai negatif ($newStock).',
            );
          }

          if (onUpdateProduct != null) {
            await onUpdateProduct!(product.copyWith(currentStock: newStock));
          }
        }
      }

      await deleteStockTransaction(id);
      if (onRefreshProducts != null) {
        await onRefreshProducts!();
      }
      await fetchTransactions();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('StateError: ', '');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
