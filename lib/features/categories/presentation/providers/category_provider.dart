import 'package:flutter/foundation.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/update_category.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/get_category_by_id.dart';

class CategoryProvider extends ChangeNotifier {
  final GetCategories getCategories;
  final AddCategory addCategory;
  final UpdateCategory updateCategory;
  final DeleteCategory deleteCategory;

  CategoryProvider({
    required this.getCategories,
    required this.addCategory,
    required this.updateCategory,
    required this.deleteCategory,
    this.getCategoryById,
  });

  final GetCategoryById? getCategoryById;

  List<CategoryEntity> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _ownerId;
  int _generation = 0;
  int _loadGeneration = 0;
  bool _disposed = false;

  void setOwner(String? ownerId) {
    if (ownerId == _ownerId) return;
    _ownerId = ownerId;
    _generation++;
    _loadGeneration++;
    _categories = [];
    _isLoading = false;
    _errorMessage = null;
    _searchQuery = '';
    notifyListeners();
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<CategoryEntity?> getCategory(String id) async {
    final generation = _generation;
    final category = await getCategoryById!(id);
    return _isCurrent(generation) ? category : null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // GETTERS
  List<CategoryEntity> get categories => List.unmodifiable(_categories);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;

    _searchQuery = query;
    notifyListeners();
  }

  // READ ALL
  Future<void> loadCategories() async {
    if (_disposed) return;
    final ownerGeneration = _generation;
    final loadGeneration = ++_loadGeneration;
    bool isCurrent() =>
        _isCurrent(ownerGeneration) && loadGeneration == _loadGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final categories = await getCategories();
      if (isCurrent()) _categories = categories;
    } catch (e) {
      if (isCurrent()) _errorMessage = 'Gagal memuat kategori: $e';
    } finally {
      if (isCurrent()) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // CREATE
  Future<bool> createCategory(CategoryEntity category) async {
    final generation = _generation;
    final nameLower = category.name.trim().toLowerCase();
    final isDuplicate = _categories.any(
      (c) => c.name.trim().toLowerCase() == nameLower,
    );
    if (isDuplicate) {
      _errorMessage = 'Nama kategori "${category.name}" sudah ada';
      notifyListeners();
      return false;
    }

    try {
      _errorMessage = null;
      await addCategory(category);
      if (!_isCurrent(generation)) return false;
      await loadCategories();
      return _isCurrent(generation);
    } catch (e) {
      if (!_isCurrent(generation)) return false;
      _errorMessage = 'Gagal menambah kategori: $e';
      notifyListeners();
      return false;
    }
  }

  // UPDATE
  Future<bool> editCategory(CategoryEntity category) async {
    final generation = _generation;
    final nameLower = category.name.trim().toLowerCase();
    final isDuplicate = _categories.any(
      (c) => c.id != category.id && c.name.trim().toLowerCase() == nameLower,
    );
    if (isDuplicate) {
      _errorMessage = 'Nama kategori "${category.name}" sudah ada';
      notifyListeners();
      return false;
    }

    try {
      _errorMessage = null;
      await updateCategory(category);
      if (!_isCurrent(generation)) return false;
      await loadCategories();
      return _isCurrent(generation);
    } catch (e) {
      if (!_isCurrent(generation)) return false;
      _errorMessage = 'Gagal mengubah kategori: $e';
      notifyListeners();
      return false;
    }
  }

  // DELETE
  Future<bool> removeCategory(String id) async {
    final generation = _generation;
    try {
      _errorMessage = null;
      await deleteCategory(id);
      if (!_isCurrent(generation)) return false;
      await loadCategories();
      return _isCurrent(generation);
    } catch (e) {
      if (!_isCurrent(generation)) return false;
      _errorMessage = 'Gagal menghapus kategori: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
