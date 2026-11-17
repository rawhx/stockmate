import 'package:flutter/foundation.dart';
import 'package:stockmate/features/suppliers/domain/entities/supplier.dart';
import 'package:stockmate/features/suppliers/domain/repositories/suppliers_repository.dart';

class SuppliersProvider extends ChangeNotifier {
  SuppliersProvider({required this.repository});

  final SuppliersRepository repository;

  List<Supplier> _items = <Supplier>[];
  bool _isLoading = false;
  String? _error;

  List<Supplier> get items => List<Supplier>.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await repository.getSuppliers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(Supplier supplier) async {
    try {
      final created = await repository.addSupplier(supplier);
      _items = <Supplier>[..._items, created];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Supplier supplier) async {
    try {
      final updated = await repository.updateSupplier(supplier);
      _items = _items
          .map((e) => e.id == updated.id ? updated : e)
          .toList(growable: false);
      _items = List<Supplier>.from(_items);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.deleteSupplier(id);
      _items = _items.where((e) => e.id != id).toList(growable: false);
      _items = List<Supplier>.from(_items);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
