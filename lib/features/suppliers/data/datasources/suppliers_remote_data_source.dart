import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/supplier_model.dart';
import 'suppliers_data_source.dart';

class SuppliersRemoteDataSource implements SuppliersDataSource {
  SuppliersRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const _pageSize = 200;
  static const _columns = 'id, name, contact_person, phone, email, address';

  String _ownerId() {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw StateError('Silakan login untuk mengakses supplier.');
    }
    return ownerId;
  }

  void _checkSession(String ownerId) {
    if (_client.auth.currentUser?.id != ownerId) {
      throw StateError('Akun telah berubah. Silakan muat ulang supplier.');
    }
  }

  Future<List<Map<String, dynamic>>> _readAll(String ownerId) async {
    final result = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += _pageSize) {
      _checkSession(ownerId);
      final page = await _client
          .from('suppliers')
          .select(_columns)
          .eq('owner_id', ownerId)
          .order('name')
          .range(offset, offset + _pageSize - 1);
      _checkSession(ownerId);
      result.addAll(page);
      if (page.length < _pageSize) break;
    }
    return result;
  }

  Future<bool> _isUsedByProducts(String supplierId, String ownerId) async {
    final rows = await _client
        .from('products')
        .select('id')
        .eq('owner_id', ownerId)
        .eq('supplier_id', supplierId)
        .limit(1);
    _checkSession(ownerId);
    return rows.isNotEmpty;
  }

  @override
  Future<List<SupplierModel>> getSuppliers() async {
    final ownerId = _ownerId();
    final rows = await _readAll(ownerId);
    _checkSession(ownerId);
    return rows.map(SupplierModel.fromJson).toList();
  }

  @override
  Future<SupplierModel> addSupplier(SupplierModel supplier) async {
    final ownerId = _ownerId();
    try {
      final row = await _client
          .from('suppliers')
          .insert({...supplier.toWriteJson(), 'owner_id': ownerId})
          .select(_columns)
          .single();
      _checkSession(ownerId);
      return SupplierModel.fromJson(row);
    } on PostgrestException catch (error) {
      _writeError(error);
    }
  }

  @override
  Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    final ownerId = _ownerId();
    try {
      final rows = await _client
          .from('suppliers')
          .update(supplier.toWriteJson())
          .eq('id', supplier.id)
          .eq('owner_id', ownerId)
          .select(_columns);
      if (rows.isEmpty) {
        throw StateError(
          'Supplier tidak ditemukan atau tidak dapat diperbarui.',
        );
      }
      _checkSession(ownerId);
      return SupplierModel.fromJson(rows.first);
    } on PostgrestException catch (error) {
      _writeError(error);
    }
  }

  @override
  Future<void> deleteSupplier(String id) async {
    final ownerId = _ownerId();
    if (id.isEmpty) {
      throw StateError('Supplier tidak valid.');
    }
    if (await _isUsedByProducts(id, ownerId)) {
      throw StateError(
        'Supplier masih digunakan produk dan tidak dapat dihapus.',
      );
    }
    try {
      final rows = await _client
          .from('suppliers')
          .delete()
          .eq('id', id)
          .eq('owner_id', ownerId)
          .select('id');
      if (rows.isEmpty) {
        throw StateError('Supplier tidak ditemukan atau tidak dapat dihapus.');
      }
    } on PostgrestException catch (error) {
      _writeError(error);
    }
    _checkSession(ownerId);
  }

  Never _writeError(PostgrestException error) {
    if (error.code == '23503') {
      throw StateError(
        'Supplier masih digunakan produk dan tidak dapat dihapus.',
      );
    }
    if (error.code == '23505') {
      throw StateError('Data supplier sudah digunakan pada akun ini.');
    }
    if (error.code == '42501') {
      throw StateError(
        'Akun ini tidak memiliki akses untuk mengubah supplier.',
      );
    }
    throw error;
  }
}
