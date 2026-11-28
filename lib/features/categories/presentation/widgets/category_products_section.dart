import 'package:flutter/material.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';

class CategoryProductsSection extends StatelessWidget {
  const CategoryProductsSection({required this.products, super.key});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Produk dalam kategori ini',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Chip(
              label: Text('${products.length}'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (products.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  const Text('Belum ada produk di kategori ini.'),
                  const SizedBox(height: 4),
                  Text(
                    'Tambahkan produk pertama menggunakan tombol di bawah.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
        else
          for (final product in products)
            Card(
              child: ListTile(
                title: Text(product.name),
                subtitle: Text(product.code),
                trailing: Text(
                  'Rp ${product.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
      ],
    );
  }
}
