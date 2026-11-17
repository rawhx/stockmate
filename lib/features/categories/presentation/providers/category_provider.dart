import 'package:flutter/foundation.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/update_category.dart';
import '../../domain/usecases/delete_category.dart';

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
  });

  List<CategoryEntity> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await getCategories();
    } catch (e) {
      _errorMessage = 'Gagal memuat kategori: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CREATE
  Future<bool> createCategory(CategoryEntity category) async {
    try {
      _errorMessage = null;
      await addCategory(category);
      await loadCategories();
      return _errorMessage == null;
    } catch (e) {
      _errorMessage = 'Gagal menambah kategori: $e';
      notifyListeners();
      return false;
    }
  }

  // UPDATE
  Future<bool> editCategory(CategoryEntity category) async {
    try {
      _errorMessage = null;
      await updateCategory(category);
      await loadCategories();
      return _errorMessage == null;
    } catch (e) {
      _errorMessage = 'Gagal mengubah kategori: $e';
      notifyListeners();
      return false;
    }
  }

  // DELETE
  Future<bool> removeCategory(String id) async {
    try {
      _errorMessage = null;
      await deleteCategory(id);
      await loadCategories();
      return _errorMessage == null;
    } catch (e) {
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
