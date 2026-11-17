import '../entities/stock_transaction.dart';
import '../repositories/stock_transaction_repository.dart';

class GetStockTransactions {
  const GetStockTransactions(this._repository);

  final StockTransactionRepository _repository;

  Future<List<StockTransaction>> call() {
    return _repository.getTransactions();
  }
}
