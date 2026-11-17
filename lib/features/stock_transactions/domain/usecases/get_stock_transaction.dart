import '../entities/stock_transaction.dart';
import '../repositories/stock_transaction_repository.dart';

class GetStockTransaction {
  const GetStockTransaction(this._repository);

  final StockTransactionRepository _repository;

  Future<StockTransaction?> call(String id) {
    return _repository.getTransaction(id);
  }
}
