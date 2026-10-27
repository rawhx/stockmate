import '../models/category_model.dart';

class CategoryMockDataSource {
  final List<CategoryModel> _categories = [
    CategoryModel(
      id: 'CAT001',
      ownerId: 'dummy-user',
      name: 'ATK',
      description: 'Alat tulis dan kebutuhan kantor',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    ),
    CategoryModel(
      id: 'CAT002',
      ownerId: 'dummy-user',
      name: 'Elektronik',
      description: 'Perangkat elektronik',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    ),
    CategoryModel(
      id: 'CAT003',
      ownerId: 'dummy-user',
      name: 'Perlengkapan',
      description: 'Perlengkapan operasional',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    ),
    CategoryModel(
      id: 'CAT004',
      ownerId: 'dummy-user',
      name: 'Alat Tulis',
      description: 'Pensil, pulpen, dan alat tulis lainnya',
      parentId: 'CAT001',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    ),
    CategoryModel(
      id: 'CAT005',
      ownerId: 'dummy-user',
      name: 'Aksesori Elektronik',
      description: 'Aksesori untuk perangkat elektronik',
      parentId: 'CAT002',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    ),
  ];

  Future<List<CategoryModel>> getCategories() async {
    return List.unmodifiable(_categories);
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Future<void> addCategory(CategoryModel category) async {
    if (_categories.any((item) => item.id == category.id)) {
      throw StateError('ID kategori sudah digunakan');
    }
    _categories.add(category);
  }

  Future<void> updateCategory(CategoryModel category) async {
    final index = _categories.indexWhere((item) => item.id == category.id);

    if (index == -1) {
      throw StateError('Kategori tidak ditemukan');
    }

    _categories[index] = category;
  }

  Future<void> deleteCategory(String id) async {
    final exists = _categories.any((item) => item.id == id);

    if (!exists) {
      throw StateError('Kategori tidak ditemukan');
    }

    if (_categories.any((item) => item.parentId == id)) {
      throw StateError('Kategori memiliki subkategori dan tidak dapat dihapus');
    }

    _categories.removeWhere((item) => item.id == id);
  }
}
