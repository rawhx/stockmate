import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';
import 'product_data_source.dart';

class ProductSupabaseDataSource implements ProductDataSource {
  const ProductSupabaseDataSource(this.client);

  final SupabaseClient client;

  String get _currentUserId {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('User belum login');
    }
    return user.id;
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    final rows = await client
        .from('products')
        .select('*, categories(name), suppliers(name)')
        .eq('owner_id', _currentUserId)
        .order('name');

    return rows.map((row) => ProductModel.fromMap(row)).toList(growable: false);
  }

  @override
  Future<ProductModel?> getProduct(String id) async {
    final row = await client
        .from('products')
        .select('*, categories(name), suppliers(name)')
        .eq('id', id)
        .eq('owner_id', _currentUserId)
        .maybeSingle();

    return row == null ? null : ProductModel.fromMap(row);
  }

  @override
  Future<void> createProduct(ProductModel product) async {
    await client.from('products').insert({
      'owner_id': _currentUserId,
      'code': product.code,
      'name': product.name,
      'price': product.price,
      'unit': product.unit,
      'category_id': product.categoryId,
      'supplier_id': product.supplierId,
      'minimum_stock': product.minimumStock,
    });
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await client
        .from('products')
        .update({
          'code': product.code,
          'name': product.name,
          'price': product.price,
          'unit': product.unit,
          'category_id': product.categoryId,
          'supplier_id': product.supplierId,
          'minimum_stock': product.minimumStock,
        })
        .eq('id', product.id)
        .eq('owner_id', _currentUserId);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await client
        .from('products')
        .delete()
        .eq('id', id)
        .eq('owner_id', _currentUserId);
  }
}
