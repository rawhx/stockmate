abstract final class ProductFormValidators {
  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  static String? positivePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required.';
    final price = double.tryParse(value.trim());
    if (price == null) return 'Enter a valid price.';
    if (price <= 0) return 'Price must be greater than zero.';
    return null;
  }

  static String? nonNegativeStock(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    final stock = int.tryParse(value.trim());
    if (stock == null) return 'Enter a whole number.';
    if (stock < 0) return '$label cannot be negative.';
    return null;
  }
}
