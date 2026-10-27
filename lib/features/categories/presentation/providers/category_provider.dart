import 'package:flutter/foundation.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_category_by_id.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/update_category.dart';
import '../../domain/usecases/delete_category.dart';

class CategoryProvider extends ChangeNotifier {
  final GetCategories getCategories;
  final GetCategoryById getCategoryById;
  final AddCategory addCategory;
  final UpdateCategory updateCategory;
  final DeleteCategory deleteCategory;

  CategoryProvider({
    required this.getCategories,
    required this.getCategoryById,
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

  // FILTER PENCARIAN
  List<CategoryEntity> get filteredCategories {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return categories;
    }

    return categories.where((category) {
      return category.name.toLowerCase().contains(query);
    }).toList();
  }

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

  // READ DETAIL
  Future<CategoryEntity?> loadCategoryById(String id) async {
    try {
      _errorMessage = null;
      return await getCategoryById(id);
    } catch (e) {
      _errorMessage = 'Gagal mengambil detail kategori: $e';
      notifyListeners();
      return null;
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
