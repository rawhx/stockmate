import 'package:stockmate/features/suppliers/domain/entities/supplier.dart';

class SupplierModel {
  const SupplierModel({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
  });

  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      // The remote table uses snake_case; mock data uses camelCase.
      contactPerson: _string(json, 'contact_person', 'contactPerson'),
      phone: _string(json, 'phone', 'phone'),
      email: _string(json, 'email', 'email'),
      address: _string(json, 'address', 'address'),
    );
  }

  static String _string(
    Map<String, dynamic> json,
    String snakeCase,
    String camelCase,
  ) {
    return (json[snakeCase] ?? json[camelCase]) as String? ?? '';
  }

  /// Payload accepted by the `suppliers` table. The ID and owner are generated
  /// by the database, so they are intentionally omitted here.
  Map<String, dynamic> toWriteJson() {
    return <String, dynamic>{
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  Supplier toEntity() {
    return Supplier(
      id: id,
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      address: address,
    );
  }

  factory SupplierModel.fromEntity(Supplier entity) {
    return SupplierModel(
      id: entity.id,
      name: entity.name,
      contactPerson: entity.contactPerson,
      phone: entity.phone,
      email: entity.email,
      address: entity.address,
    );
  }
}
