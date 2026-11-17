import '../repositories/stock_transaction_repository.dart';

class DeleteStockTransaction {
  const DeleteStockTransaction(this._repository);

  final StockTransactionRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteTransaction(id);
  }
}
