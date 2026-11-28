import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/features/categories/domain/entities/category_entity.dart';
import 'package:stockmate/features/categories/domain/repositories/category_repository.dart';
import 'package:stockmate/features/categories/domain/usecases/add_category.dart';
import 'package:stockmate/features/categories/domain/usecases/delete_category.dart';
import 'package:stockmate/features/categories/domain/usecases/get_categories.dart';
import 'package:stockmate/features/categories/domain/usecases/get_category_by_id.dart';
import 'package:stockmate/features/categories/domain/usecases/update_category.dart';
import 'package:stockmate/features/categories/presentation/providers/category_provider.dart';

class _CategoryRepository implements CategoryRepository {
  final list = Completer<List<CategoryEntity>>();
  final detail = Completer<CategoryEntity?>();

  @override
  Future<List<CategoryEntity>> getCategories() => list.future;

  @override
  Future<CategoryEntity?> getCategory(String id) => detail.future;

  @override
  Future<void> addCategory(CategoryEntity category) => throw UnimplementedError();

  @override
  Future<void> updateCategory(CategoryEntity category) => throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) => throw UnimplementedError();
}

void main() {
  test('pending reads from a previous account cannot repopulate its category data', () async {
    final repository = _CategoryRepository();
    final provider = CategoryProvider(
      getCategories: GetCategories(repository),
      getCategoryById: GetCategoryById(repository),
      addCategory: AddCategory(repository),
      updateCategory: UpdateCategory(repository),
      deleteCategory: DeleteCategory(repository),
    );
    addTearDown(provider.dispose);
    final previous = CategoryEntity(
      id: 'a-category',
      ownerId: 'a',
      name: 'Private inventory',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    provider.setOwner('a');
    provider.setSearchQuery(previous.name);
    final list = provider.loadCategories();
    final detail = provider.getCategory(previous.id);
    provider.setOwner('b');
    repository.list.complete([previous]);
    repository.detail.complete(previous);

    await list;
    expect(await detail, isNull);
    expect(provider.categories, isEmpty);
    expect(provider.searchQuery, isEmpty);
    expect(provider.isLoading, isFalse);
  });
}
