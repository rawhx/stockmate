import 'package:stockmate/features/suppliers/data/datasources/suppliers_local_data_source.dart';
import 'package:stockmate/features/suppliers/data/models/supplier_model.dart';
import 'package:stockmate/features/suppliers/domain/entities/supplier.dart';
import 'package:stockmate/features/suppliers/domain/repositories/suppliers_repository.dart';

class SuppliersRepositoryImpl implements SuppliersRepository {
  SuppliersRepositoryImpl({required this.localDataSource});

  final SuppliersLocalDataSource localDataSource;

  @override
  Future<List<Supplier>> getSuppliers() async {
    final models = await localDataSource.getSuppliers();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Supplier> addSupplier(Supplier supplier) async {
    final model = SupplierModel.fromEntity(supplier);
    final result = await localDataSource.addSupplier(model);
    return result.toEntity();
  }

  @override
  Future<Supplier> updateSupplier(Supplier supplier) async {
    final model = SupplierModel.fromEntity(supplier);
    final result = await localDataSource.updateSupplier(model);
    return result.toEntity();
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await localDataSource.deleteSupplier(id);
  }
}
