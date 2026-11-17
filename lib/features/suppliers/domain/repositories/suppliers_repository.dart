import 'package:stockmate/features/suppliers/domain/entities/supplier.dart';

abstract class SuppliersRepository {
  Future<List<Supplier>> getSuppliers();
  Future<Supplier> addSupplier(Supplier supplier);
  Future<Supplier> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
}
