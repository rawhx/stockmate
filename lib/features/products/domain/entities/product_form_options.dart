class ProductOption {
  const ProductOption({required this.id, required this.name});

  final String id;
  final String name;
}

class ProductFormOptions {
  const ProductFormOptions({required this.categories, required this.suppliers});

  final List<ProductOption> categories;
  final List<ProductOption> suppliers;
}
