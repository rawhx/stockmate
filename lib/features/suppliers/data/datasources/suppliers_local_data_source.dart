import 'package:stockmate/features/suppliers/data/models/supplier_model.dart';

abstract class SuppliersLocalDataSource {
  Future<List<SupplierModel>> getSuppliers();
  Future<SupplierModel> addSupplier(SupplierModel supplier);
  Future<SupplierModel> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String id);
}

class SuppliersLocalDataSourceImpl implements SuppliersLocalDataSource {
  SuppliersLocalDataSourceImpl() {
    _items.addAll(_initial);
  }

  final List<SupplierModel> _items = <SupplierModel>[];

  static final List<SupplierModel> _initial = <SupplierModel>[
    const SupplierModel(
      id: 'sup-001',
      name: 'PT Sumber Makmur',
      contactPerson: 'Budi Santoso',
      phone: '+62 812-3456-7890',
      email: 'budi@sumbermakmur.co.id',
      address: 'Jl. Industri Raya No. 45, Bekasi, Jawa Barat',
    ),
    const SupplierModel(
      id: 'sup-002',
      name: 'CV Maju Bersama',
      contactPerson: 'Siti Rahma',
      phone: '+62 813-9876-5432',
      email: 'siti@majubersama.id',
      address: 'Jl. Perdagangan 12, Bandung, Jawa Barat',
    ),
    const SupplierModel(
      id: 'sup-003',
      name: 'UD Jaya Abadi',
      contactPerson: 'Agus Wijaya',
      phone: '+62 821-4567-8901',
      email: 'agus@jayaabadi.com',
      address: 'Jl. Pasar Baru No. 8, Surabaya, Jawa Timur',
    ),
    const SupplierModel(
      id: 'sup-004',
      name: 'PT Global Prima',
      contactPerson: 'Dewi Lestari',
      phone: '+62 822-1122-3344',
      email: 'dewi@globalprima.co.id',
      address: 'Jl. Gatot Subroto Kav. 56, Jakarta Selatan',
    ),
  ];

  @override
  Future<List<SupplierModel>> getSuppliers() async {
    return List<SupplierModel>.unmodifiable(_items);
  }

  @override
  Future<SupplierModel> addSupplier(SupplierModel supplier) async {
    final newItem = supplier.id.isEmpty
        ? SupplierModel(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: supplier.name,
            contactPerson: supplier.contactPerson,
            phone: supplier.phone,
            email: supplier.email,
            address: supplier.address,
          )
        : supplier;
    _items.add(newItem);
    return newItem;
  }

  @override
  Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    final index = _items.indexWhere((e) => e.id == supplier.id);
    if (index >= 0) {
      _items[index] = supplier;
      return supplier;
    }
    _items.add(supplier);
    return supplier;
  }

  @override
  Future<void> deleteSupplier(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}
