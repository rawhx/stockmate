import '../models/supplier_model.dart';

abstract interface class SuppliersDataSource {
  Future<List<SupplierModel>> getSuppliers();

  Future<SupplierModel> addSupplier(SupplierModel supplier);

  Future<SupplierModel> updateSupplier(SupplierModel supplier);

  Future<void> deleteSupplier(String id);
}
