import 'package:flutter/material.dart';

enum TransactionType {
  inStock('Masuk', Icons.arrow_downward_rounded, Color(0xFF2E7D32)),
  outStock('Keluar', Icons.arrow_upward_rounded, Color(0xFFC62828));

  const TransactionType(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  bool get isIn => this == TransactionType.inStock;
  bool get isOut => this == TransactionType.outStock;

  static TransactionType fromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'in' ||
        normalized == 'instock' ||
        normalized == 'masuk') {
      return TransactionType.inStock;
    }
    return TransactionType.outStock;
  }
}
