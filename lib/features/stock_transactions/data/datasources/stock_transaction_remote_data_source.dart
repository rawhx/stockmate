import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/stock_transaction_model.dart';
import 'stock_transaction_data_source.dart';

class StockTransactionRemoteDataSource implements StockTransactionDataSource {
  StockTransactionRemoteDataSource(this._client);

  final SupabaseClient _client;

  String _ownerId() {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw StateError('Silakan login untuk mengakses transaksi stok.');
    }
    return ownerId;
  }

  void _checkSession(String ownerId) {
    if (_client.auth.currentUser?.id != ownerId) {
      throw StateError('Akun telah berubah. Silakan muat ulang transaksi stok.');
    }
  }

  static const _selectQuery =
      'id, product_id, type, quantity, transaction_date, note, created_at, products(code, name)';

  Never _handlePostgrestError(PostgrestException error) {
    final code = error.code;
    if (code == '23503') {
      throw StateError('Produk referensi tidak ditemukan atau telah dihapus.');
    }
    if (code == '42501') {
      throw StateError('Akses ditolak. Periksa autentikasi Anda.');
    }
    if (error.message.contains('schema cache') || code == 'PGRST204') {
      throw StateError(
        'Skema database Supabase belum sesuai atau belum diperbarui. '
        'Pastikan nama tabel adalah "stock_transactions", kolom "transaction_date" dan "note" sudah sesuai, '
        'dan reload schema cache Supabase dengan query: NOTIFY pgrst, \'reload schema\';',
      );
    }
    throw StateError(error.message);
  }

  @override
  Future<List<StockTransactionModel>> getTransactions() async {
    final ownerId = _ownerId();
    try {
      final rows = await _client
          .from('stock_transactions')
          .select(_selectQuery)
          .eq('owner_id', ownerId)
          .order('transaction_date', ascending: false);
      _checkSession(ownerId);
      return rows
          .map((row) => StockTransactionModel.fromJson(row))
          .toList();
    } on PostgrestException catch (error) {
      _handlePostgrestError(error);
    }
  }

  @override
  Future<StockTransactionModel?> getTransaction(String id) async {
    final ownerId = _ownerId();
    try {
      final row = await _client
          .from('stock_transactions')
          .select(_selectQuery)
          .eq('owner_id', ownerId)
          .eq('id', id)
          .maybeSingle();
      _checkSession(ownerId);
      if (row == null) return null;
      return StockTransactionModel.fromJson(row);
    } on PostgrestException catch (error) {
      _handlePostgrestError(error);
    }
  }

  @override
  Future<StockTransactionModel> createTransaction(
    StockTransactionModel transaction,
  ) async {
    final ownerId = _ownerId();
    try {
      final insertData = {
        ...transaction.toWriteJson(),
        'owner_id': ownerId,
      };
      final row = await _client
          .from('stock_transactions')
          .insert(insertData)
          .select(_selectQuery)
          .single();
      _checkSession(ownerId);
      return StockTransactionModel.fromJson(row);
    } on PostgrestException catch (error) {
      _handlePostgrestError(error);
    }
  }

  @override
  Future<StockTransactionModel> updateTransaction(
    StockTransactionModel transaction,
  ) async {
    final ownerId = _ownerId();
    try {
      final updateData = transaction.toWriteJson();
      final row = await _client
          .from('stock_transactions')
          .update(updateData)
          .eq('id', transaction.id)
          .eq('owner_id', ownerId)
          .select(_selectQuery)
          .single();
      _checkSession(ownerId);
      return StockTransactionModel.fromJson(row);
    } on PostgrestException catch (error) {
      _handlePostgrestError(error);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final ownerId = _ownerId();
    try {
      await _client
          .from('stock_transactions')
          .delete()
          .eq('id', id)
          .eq('owner_id', ownerId);
      _checkSession(ownerId);
    } on PostgrestException catch (error) {
      _handlePostgrestError(error);
    }
  }
}
