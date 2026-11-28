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
  bool _isSaving = false;
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
  bool get isLoading => _isLoading || _isSaving;
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
    _isSaving = false;
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
    final generation = _generation;
    _errorMessage = null;
    try {
      final transaction = await getStockTransaction(id);
      return !_disposed && generation == _generation ? transaction : null;
    } catch (e) {
      if (!_disposed && generation == _generation) {
        _errorMessage = e is StateError ? e.message : e.toString();
        notifyListeners();
      }
      return null;
    }
  }

  Future<bool> addTransaction(StockTransaction transaction) => _mutate(
    next: transaction,
    write: (_, next) => createStockTransaction(next!),
  );

  Future<bool> editTransaction(StockTransaction updated) => _mutate(
    previousId: updated.id,
    next: updated,
    write: (_, next) => updateStockTransaction(next!),
  );

  Future<bool> removeTransaction(String id) => _mutate(
    previousId: id,
    write: (previous, _) => deleteStockTransaction(previous!.id),
  );

  Future<bool> _mutate({
    String? previousId,
    StockTransaction? next,
    required Future<void> Function(StockTransaction?, StockTransaction?) write,
  }) async {
    if (_isSaving || _disposed) return false;
    final generation = _generation;
    bool isCurrent() => !_disposed && generation == _generation;
    final updateProduct = onUpdateProduct;
    final attempted = <Product>[];
    var committed = false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (next != null && next.quantity <= 0) {
        throw StateError('Jumlah transaksi harus lebih dari nol.');
      }

      final previous = previousId == null
          ? null
          : await getStockTransaction(previousId);
      if (!isCurrent()) return false;
      if (previousId != null && previous == null) {
        throw StateError('Transaksi tidak ditemukan.');
      }

      final products = await _collectStockChanges(previous, next);
      if (!isCurrent()) return false;
      if (updateProduct != null) {
        for (final (original, updated) in products) {
          attempted.add(original);
          if (!await updateProduct(updated)) {
            throw StateError('Gagal memperbarui stok ${original.name}.');
          }
          if (!isCurrent()) return false;
        }
      }
      await write(previous, next);
      committed = true;
      if (!isCurrent()) return false;

      final pending = _pendingFetch;
      if (pending != null) await pending;
      if (!isCurrent()) return false;
      await onRefreshProducts?.call();
      if (!isCurrent()) return false;
      await fetchTransactions();
      return isCurrent();
    } catch (error) {
      if (!isCurrent()) return false;
      final message = error is StateError ? error.message : error.toString();
      var rollbackFailed = false;
      if (!committed && updateProduct != null) {
        for (final product in attempted.reversed) {
          if (!isCurrent()) return false;
          try {
            if (!await updateProduct(product)) rollbackFailed = true;
          } catch (_) {
            rollbackFailed = true;
          }
        }
      }
      if (!isCurrent()) return false;
      _errorMessage = rollbackFailed ? '$message Pemulihan stok gagal.' : message;
      return committed;
    } finally {
      if (isCurrent()) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<List<(Product, Product)>> _collectStockChanges(
    StockTransaction? previous,
    StockTransaction? next,
  ) async {
    final getProduct = onGetProduct;
    if (getProduct == null) return [];
    final changes = <(Product, Product)>[];
    final deltas = StockTransaction.stockDeltas(previous: previous, next: next);
    for (final entry in deltas.entries) {
      final product = await getProduct(entry.key);
      if (product == null) throw StateError('Produk transaksi tidak ditemukan.');
      final balance = product.currentStock + entry.value;
      if (entry.value < 0 && balance < 0) {
        throw StateError('Stok tidak mencukupi untuk ${product.name}.');
      }
      if (entry.value != 0) {
        changes.add((product, product.copyWith(currentStock: balance)));
      }
    }
    return changes;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
