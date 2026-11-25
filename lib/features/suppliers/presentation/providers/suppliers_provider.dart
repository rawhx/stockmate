import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/supplier.dart';
import '../../domain/usecases/supplier_usecases.dart';

class SuppliersProvider extends ChangeNotifier {
  factory SuppliersProvider({
    required GetSuppliers getSuppliers,
    required AddSupplier addSupplier,
    required UpdateSupplier updateSupplier,
    required DeleteSupplier deleteSupplier,
  }) => SuppliersProvider._(
    getSuppliers,
    addSupplier,
    updateSupplier,
    deleteSupplier,
  );

  SuppliersProvider._(
    this._getSuppliers,
    this._addSupplier,
    this._updateSupplier,
    this._deleteSupplier,
  );

  final GetSuppliers _getSuppliers;
  final AddSupplier _addSupplier;
  final UpdateSupplier _updateSupplier;
  final DeleteSupplier _deleteSupplier;

  List<Supplier> _items = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _disposed = false;
  int _generation = 0;
  String? _ownerId;
  bool _hasOwner = false;
  String? _errorMessage;
  Future<void>? _pendingFetch;

  List<Supplier> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Clears cached suppliers when the signed-in account changes.
  void setOwner(String? ownerId) {
    if (_hasOwner && ownerId == _ownerId) return;
    _hasOwner = true;
    _ownerId = ownerId;
    _generation++;
    _items = [];
    _errorMessage = null;
    _pendingFetch = null;
    _isLoading = false;
    _isSaving = false;
    _notify();
    if (ownerId != null) {
      final generation = _generation;
      scheduleMicrotask(() {
        if (_isCurrent(generation)) unawaited(fetchSuppliers());
      });
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<void> fetchSuppliers() {
    if (_pendingFetch != null) return _pendingFetch!;
    final request = _fetchSuppliers(_generation);
    _pendingFetch = request;
    return request.whenComplete(() {
      if (identical(_pendingFetch, request)) _pendingFetch = null;
    });
  }

  Future<void> _fetchSuppliers(int generation) async {
    _isLoading = true;
    _notify();
    try {
      final suppliers = await _getSuppliers();
      if (!_isCurrent(generation)) return;
      _items = suppliers;
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

  Future<bool> add(Supplier supplier) {
    final generation = _generation;
    return _mutate(() async {
      final created = await _addSupplier(supplier);
      if (_isCurrent(generation)) _items = <Supplier>[..._items, created];
    });
  }

  Future<bool> update(Supplier supplier) {
    final generation = _generation;
    return _mutate(() async {
      final updated = await _updateSupplier(supplier);
      if (_isCurrent(generation)) {
        _items = _items
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false);
      }
    });
  }

  Future<bool> delete(String id) {
    final generation = _generation;
    return _mutate(() async {
      await _deleteSupplier(id);
      if (_isCurrent(generation)) {
        _items = _items.where((item) => item.id != id).toList(growable: false);
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
      await fetchSuppliers();
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
