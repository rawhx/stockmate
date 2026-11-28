import '../models/stock_transaction_model.dart';

abstract class StockTransactionDataSource {
  Future<List<StockTransactionModel>> getTransactions();

  Future<StockTransactionModel?> getTransaction(String id);

  Future<StockTransactionModel> createTransaction(
    StockTransactionModel transaction,
  );

  Future<StockTransactionModel> updateTransaction(
    StockTransactionModel transaction,
  );

  Future<void> deleteTransaction(String id);
}
