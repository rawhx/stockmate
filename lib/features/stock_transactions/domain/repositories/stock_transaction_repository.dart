import '../entities/stock_transaction.dart';

abstract class StockTransactionRepository {
  Future<List<StockTransaction>> getTransactions();

  Future<StockTransaction?> getTransaction(String id);

  Future<StockTransaction> createTransaction(StockTransaction transaction);

  Future<StockTransaction> updateTransaction(StockTransaction transaction);

  Future<void> deleteTransaction(String id);
}
