import 'package:stockmate/features/suppliers/data/datasources/suppliers_data_source.dart';
import 'package:stockmate/features/suppliers/data/models/supplier_model.dart';
import 'package:stockmate/features/suppliers/domain/entities/supplier.dart';
import 'package:stockmate/features/suppliers/domain/repositories/suppliers_repository.dart';

class SuppliersRepositoryImpl implements SuppliersRepository {
  SuppliersRepositoryImpl({required this.dataSource});

  final SuppliersDataSource dataSource;

  @override
  Future<List<Supplier>> getSuppliers() async {
    final models = await dataSource.getSuppliers();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Supplier> addSupplier(Supplier supplier) async {
    final model = SupplierModel.fromEntity(supplier);
    final result = await dataSource.addSupplier(model);
    return result.toEntity();
  }

  @override
  Future<Supplier> updateSupplier(Supplier supplier) async {
    final model = SupplierModel.fromEntity(supplier);
    final result = await dataSource.updateSupplier(model);
    return result.toEntity();
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await dataSource.deleteSupplier(id);
  }
}
