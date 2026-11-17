import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';

class CategoryProductPickerDialog extends StatefulWidget {
  const CategoryProductPickerDialog({required this.categoryName, super.key});

  final String categoryName;

  @override
  State<CategoryProductPickerDialog> createState() =>
      _CategoryProductPickerDialogState();
}

class _CategoryProductPickerDialogState
    extends State<CategoryProductPickerDialog> {
  final _selectedProductIds = <String>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final productProvider = context.read<ProductProvider>();
    final normalizedQuery = _query.trim().toLowerCase();
    final products = productProvider.products.where((product) {
      return normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.code.toLowerCase().contains(normalizedQuery);
    }).toList();

    return AlertDialog(
      title: Text('Pilih Produk untuk ${widget.categoryName}'),
      content: SizedBox(
        width: 500,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari produk atau kode',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('Produk tidak ditemukan.'))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final currentCategory =
                            product.categoryName.trim().isEmpty
                            ? 'Belum memiliki kategori'
                            : product.categoryName;

                        return CheckboxListTile(
                          value: _selectedProductIds.contains(product.id),
                          onChanged: (isSelected) {
                            setState(() {
                              if (isSelected == true) {
                                _selectedProductIds.add(product.id);
                              } else {
                                _selectedProductIds.remove(product.id);
                              }
                            });
                          },
                          title: Text(product.name),
                          subtitle: Text(
                            '${product.code} - Saat ini: $currentCategory',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _selectedProductIds.isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  productProvider.products
                      .where(
                        (product) => _selectedProductIds.contains(product.id),
                      )
                      .toList(),
                ),
          icon: const Icon(Icons.link),
          label: const Text('Tambahkan Produk'),
        ),
      ],
    );
  }
}
