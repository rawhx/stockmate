import 'package:stockmate/features/suppliers/domain/entities/supplier.dart';
import 'package:stockmate/features/suppliers/domain/repositories/suppliers_repository.dart';

class GetSuppliers {
  GetSuppliers(this.repository);

  final SuppliersRepository repository;

  Future<List<Supplier>> call() {
    return repository.getSuppliers();
  }
}

class AddSupplier {
  AddSupplier(this.repository);

  final SuppliersRepository repository;

  Future<Supplier> call(Supplier supplier) {
    return repository.addSupplier(supplier);
  }
}

class UpdateSupplier {
  UpdateSupplier(this.repository);

  final SuppliersRepository repository;

  Future<Supplier> call(Supplier supplier) {
    return repository.updateSupplier(supplier);
  }
}

class DeleteSupplier {
  DeleteSupplier(this.repository);

  final SuppliersRepository repository;

  Future<void> call(String id) {
    return repository.deleteSupplier(id);
  }
}
