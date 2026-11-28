import '../../domain/entities/stock_transaction.dart';
import '../../domain/repositories/stock_transaction_repository.dart';
import '../datasources/stock_transaction_data_source.dart';
import '../models/stock_transaction_model.dart';

class StockTransactionRepositoryImpl implements StockTransactionRepository {
  StockTransactionRepositoryImpl(this._dataSource);

  final StockTransactionDataSource _dataSource;

  StockTransactionDataSource get dataSource => _dataSource;

  @override
  Future<List<StockTransaction>> getTransactions() async {
    return _dataSource.getTransactions();
  }

  @override
  Future<StockTransaction?> getTransaction(String id) async {
    return _dataSource.getTransaction(id);
  }

  @override
  Future<StockTransaction> createTransaction(StockTransaction transaction) {
    return _dataSource.createTransaction(
      StockTransactionModel.fromEntity(transaction),
    );
  }

  @override
  Future<StockTransaction> updateTransaction(StockTransaction transaction) {
    return _dataSource.updateTransaction(
      StockTransactionModel.fromEntity(transaction),
    );
  }

  @override
  Future<void> deleteTransaction(String id) {
    return _dataSource.deleteTransaction(id);
  }
}
