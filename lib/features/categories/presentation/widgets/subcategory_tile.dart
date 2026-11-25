import 'package:flutter/material.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';

import '../../domain/entities/category_entity.dart';

class SubcategoryTile extends StatefulWidget {
  const SubcategoryTile({
    required this.category,
    required this.products,
    required this.onOpen,
    required this.onAddProduct,
    super.key,
  });

  final CategoryEntity category;
  final List<Product> products;
  final VoidCallback onOpen;
  final VoidCallback onAddProduct;

  @override
  State<SubcategoryTile> createState() => _SubcategoryTileState();
}

class _SubcategoryTileState extends State<SubcategoryTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.subdirectory_arrow_right),
        title: Text(widget.category.name),
        subtitle: Text('${widget.products.length} produk'),
        onExpansionChanged: (expanded) =>
            setState(() => _isExpanded = expanded),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Lihat detail ${widget.category.name}',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.open_in_new_outlined, size: 19),
              onPressed: widget.onOpen,
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        children: [
          if (widget.products.isEmpty)
            const ListTile(
              contentPadding: EdgeInsets.only(left: 56, right: 16),
              title: Text('Belum ada produk pada subkategori ini.'),
            )
          else
            for (final product in widget.products)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 56, right: 16),
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(product.name),
                subtitle: Text(
                  '${product.code} | Rp ${product.price.toStringAsFixed(0)}',
                ),
              ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 8),
              child: TextButton.icon(
                onPressed: widget.onAddProduct,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah produk'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
