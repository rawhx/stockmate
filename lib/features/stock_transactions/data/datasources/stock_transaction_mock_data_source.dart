import '../../domain/entities/transaction_type.dart';
import '../models/stock_transaction_model.dart';

class StockTransactionMockDataSource {
  final List<StockTransactionModel> _transactions = [
    StockTransactionModel(
      id: 'tx-1',
      productId: '1',
      productName: 'Beras Premium',
      productCode: 'PRD-001',
      type: TransactionType.inStock,
      quantity: 30,
      date: DateTime.now().subtract(const Duration(days: 3)),
      notes: 'Penerimaan stok awal dari supplier PT Sumber Pangan',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    StockTransactionModel(
      id: 'tx-2',
      productId: '1',
      productName: 'Beras Premium',
      productCode: 'PRD-001',
      type: TransactionType.outStock,
      quantity: 5,
      date: DateTime.now().subtract(const Duration(days: 2)),
      notes: 'Penjualan ke pelanggan Toko Berkah',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StockTransactionModel(
      id: 'tx-3',
      productId: '2',
      productName: 'Mineral Water 600ml',
      productCode: 'PRD-002',
      type: TransactionType.inStock,
      quantity: 20,
      date: DateTime.now().subtract(const Duration(days: 2)),
      notes: 'Restock mingguan dari CV Tirta Sejahtera',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StockTransactionModel(
      id: 'tx-4',
      productId: '2',
      productName: 'Mineral Water 600ml',
      productCode: 'PRD-002',
      type: TransactionType.outStock,
      quantity: 8,
      date: DateTime.now().subtract(const Duration(days: 1)),
      notes: 'Penjualan retail',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    StockTransactionModel(
      id: 'tx-5',
      productId: '3',
      productName: 'Cooking Oil 1L',
      productCode: 'PRD-003',
      type: TransactionType.inStock,
      quantity: 30,
      date: DateTime.now().subtract(const Duration(hours: 12)),
      notes: 'Pengiriman batch 2',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  Future<List<StockTransactionModel>> getTransactions() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final sorted = List<StockTransactionModel>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  Future<StockTransactionModel?> getTransaction(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    try {
      return _transactions.firstWhere((tx) => tx.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<StockTransactionModel> createTransaction(
    StockTransactionModel transaction,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _transactions.insert(0, transaction);
    return transaction;
  }

  Future<StockTransactionModel> updateTransaction(
    StockTransactionModel transaction,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _transactions.indexWhere((tx) => tx.id == transaction.id);
    if (index == -1) {
      throw StateError('Transaksi dengan ID ${transaction.id} tidak ditemukan');
    }
    _transactions[index] = transaction;
    return transaction;
  }

  Future<void> deleteTransaction(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index == -1) {
      throw StateError('Transaksi dengan ID $id tidak ditemukan');
    }
    _transactions.removeAt(index);
  }
}
