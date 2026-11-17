import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/product_form_options.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const _pageSize = 200;

  String _ownerId() {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw StateError('Silakan login untuk mengakses produk.');
    }
    return ownerId;
  }

  void _checkSession(String ownerId) {
    if (_client.auth.currentUser?.id != ownerId) {
      throw StateError('Akun telah berubah. Silakan muat ulang produk.');
    }
  }

  // Page through the API instead of silently stopping at its default row limit.
  Future<List<Map<String, dynamic>>> _readAll(
    String table,
    String columns,
    String ownerId, {
    List<String>? ids,
  }) async {
    final result = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += _pageSize) {
      _checkSession(ownerId);
      var query = _client.from(table).select(columns).eq('owner_id', ownerId);
      if (ids != null) query = query.inFilter('id', ids);
      final page = await query
          .order('id')
          .range(offset, offset + _pageSize - 1);
      _checkSession(ownerId);
      result.addAll(page);
      if (page.length < _pageSize) break;
    }
    return result;
  }

  Future<Map<String, String>> _getNames(
    String table,
    Iterable<String> ids,
    String ownerId,
  ) async {
    final uniqueIds = ids.toSet().toList();
    final names = <String, String>{};
    // Keep the URL bounded even when the inventory contains many references.
    for (var offset = 0; offset < uniqueIds.length; offset += 100) {
      final end = offset + 100 < uniqueIds.length
          ? offset + 100
          : uniqueIds.length;
      final rows = await _readAll(
        table,
        'id, name',
        ownerId,
        ids: uniqueIds.sublist(offset, end),
      );
      for (final row in rows) {
        names[row['id'] as String] = row['name'] as String;
      }
    }
    return names;
  }

  Future<List<ProductModel>> _mapProducts(
    List<Map<String, dynamic>> rows,
    String ownerId,
  ) async {
    if (rows.isEmpty) return [];
    final names = await Future.wait([
      _getNames(
        'categories',
        rows.map((row) => row['category_id'] as String),
        ownerId,
      ),
      _getNames(
        'suppliers',
        rows.map((row) => row['supplier_id']).whereType<String>(),
        ownerId,
      ),
    ]);
    _checkSession(ownerId);
    final products = rows
        .map(
          (row) => ProductModel.fromJson(
            row,
            categoryName:
                names[0][row['category_id']] ?? 'Kategori tidak tersedia',
            supplierName: names[1][row['supplier_id']],
          ),
        )
        .toList();
    products.sort((a, b) {
      final nameOrder = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return nameOrder != 0 ? nameOrder : a.id.compareTo(b.id);
    });
    return products;
  }

  Future<List<ProductModel>> getProducts() async {
    final ownerId = _ownerId();
    final rows = await _readAll('product_stock_summary', '*', ownerId);
    return _mapProducts(rows, ownerId);
  }

  Future<ProductModel?> getProduct(String id) async {
    final ownerId = _ownerId();
    final row = await _client
        .from('product_stock_summary')
        .select()
        .eq('owner_id', ownerId)
        .eq('id', id)
        .maybeSingle();
    _checkSession(ownerId);
    if (row == null) return null;
    return (await _mapProducts([row], ownerId)).single;
  }

  Future<ProductFormOptions> getFormOptions() async {
    final ownerId = _ownerId();
    final rows = await Future.wait([
      _readAll('categories', 'id, name', ownerId),
      _readAll('suppliers', 'id, name', ownerId),
    ]);
    List<ProductOption> options(List<Map<String, dynamic>> items) {
      final result =
          items
              .map(
                (row) => ProductOption(
                  id: row['id'] as String,
                  name: row['name'] as String,
                ),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      return List.unmodifiable(result);
    }

    return ProductFormOptions(
      categories: options(rows[0]),
      suppliers: options(rows[1]),
    );
  }

  Future<void> _validateReferences(ProductModel product, String ownerId) async {
    final names = await Future.wait([
      _getNames('categories', [product.categoryId], ownerId),
      _getNames('suppliers', [
        if (product.supplierId != null) product.supplierId!,
      ], ownerId),
    ]);
    if (!names[0].containsKey(product.categoryId)) {
      throw StateError('Pilih kategori yang tersedia pada akun ini.');
    }
    if (product.supplierId != null &&
        !names[1].containsKey(product.supplierId)) {
      throw StateError('Pilih supplier yang tersedia pada akun ini.');
    }
    _checkSession(ownerId);
  }

  Future<void> createProduct(ProductModel product) async {
    final ownerId = _ownerId();
    if (product.currentStock != 0) {
      throw StateError('Stok awal harus dicatat melalui transaksi stok.');
    }
    await _validateReferences(product, ownerId);
    try {
      await _client
          .from('products')
          .insert({...product.toWriteJson(), 'owner_id': ownerId})
          .select('id')
          .single();
    } on PostgrestException catch (error) {
      _writeError(error);
    }
    _checkSession(ownerId);
  }

  Future<void> updateProduct(ProductModel product) async {
    final ownerId = _ownerId();
    final existing = await _client
        .from('product_stock_summary')
        .select('current_stock')
        .eq('id', product.id)
        .eq('owner_id', ownerId)
        .maybeSingle();
    _checkSession(ownerId);
    if (existing == null) {
      throw StateError('Produk tidak ditemukan atau tidak dapat diakses.');
    }
    if (product.currentStock != (existing['current_stock'] as num).toInt()) {
      throw StateError(
        'Stok telah berubah. Muat ulang produk; stok dikelola melalui transaksi.',
      );
    }
    await _validateReferences(product, ownerId);
    try {
      final updated = await _client
          .from('products')
          .update(product.toWriteJson())
          .eq('id', product.id)
          .eq('owner_id', ownerId)
          .select('id');
      if (updated.isEmpty) {
        throw StateError('Produk tidak ditemukan atau tidak dapat diperbarui.');
      }
    } on PostgrestException catch (error) {
      _writeError(error);
    }
    _checkSession(ownerId);
  }

  Never _writeError(PostgrestException error) {
    if (error.code == '23503') {
      throw StateError(
        'Produk masih memiliki transaksi atau referensi kategori/supplier tidak tersedia.',
      );
    }
    if (error.code == '23505') {
      throw StateError('Kode produk sudah digunakan pada akun ini.');
    }
    if (error.code == '42501') {
      throw StateError('Akun ini tidak memiliki akses untuk mengubah produk.');
    }
    throw error;
  }
}
