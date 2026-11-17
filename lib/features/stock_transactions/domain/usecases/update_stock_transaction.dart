import '../entities/stock_transaction.dart';
import '../repositories/stock_transaction_repository.dart';

class UpdateStockTransaction {
  const UpdateStockTransaction(this._repository);

  final StockTransactionRepository _repository;

  Future<StockTransaction> call(StockTransaction transaction) {
    return _repository.updateTransaction(transaction);
  }
}
