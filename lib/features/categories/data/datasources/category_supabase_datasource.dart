import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';

class CategorySupabaseDataSource {
  final SupabaseClient? client;

  const CategorySupabaseDataSource([this.client]);

  String get _currentUserId {
    final user = client?.auth.currentUser;

    if (user == null) {
      throw StateError('User belum login');
    }

    return user.id;
  }

  Future<List<CategoryModel>> getCategories() async {
    final client = this.client;
    if (client == null) {
      final now = DateTime.now();
      return [
        CategoryModel(
          id: 'cat-1',
          ownerId: 'mock-owner',
          name: 'ATK',
          description: 'Alat tulis kantor',
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          id: 'cat-2',
          ownerId: 'mock-owner',
          name: 'Elektronik',
          description: 'Peralatan elektronik',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }

    final rows = await client
        .from('categories')
        .select()
        .eq('owner_id', _currentUserId)
        .order('name');

    return rows
        .map((row) => CategoryModel.fromMap(row))
        .toList(growable: false);
  }

  Future<CategoryModel> addCategory(CategoryModel category) async {
    final client = this.client;
    if (client == null) {
      return category;
    }

    final row = await client
        .from('categories')
        .insert({
          'owner_id': _currentUserId,
          'name': category.name,
          'description': category.description,
          'parent_id': category.parentId,
        })
        .select()
        .single();

    return CategoryModel.fromMap(row);
  }

  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final client = this.client;
    if (client == null) {
      return category;
    }

    final row = await client
        .from('categories')
        .update({
          'name': category.name,
          'description': category.description,
          'parent_id': category.parentId,
        })
        .eq('id', category.id)
        .eq('owner_id', _currentUserId)
        .select()
        .single();

    return CategoryModel.fromMap(row);
  }

  Future<void> deleteCategory(String id) async {
    final client = this.client;
    if (client == null) return;

    await client
        .from('categories')
        .delete()
        .eq('id', id)
        .eq('owner_id', _currentUserId);
  }
}
