import 'package:flutter/material.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';

import '../../domain/entities/category_entity.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.products,
    required this.isEditMode,
    required this.isExpanded,
    required this.onExpanded,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final CategoryEntity category;
  final List<Product> products;
  final bool isEditMode;
  final bool isExpanded;
  final ValueChanged<bool> onExpanded;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.folder_outlined, size: 19),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${products.length} produk'),
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpanded,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Lihat detail ${category.name}',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.open_in_new_outlined, size: 19),
              onPressed: onOpen,
            ),
            if (isEditMode) ...[
              IconButton(
                tooltip: 'Edit ${category.name}',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Hapus ${category.name}',
                visualDensity: VisualDensity.compact,
                color: colorScheme.error,
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        children: [
          if (products.isEmpty)
            const ListTile(
              leading: Icon(Icons.inventory_2_outlined),
              title: Text('Belum ada produk pada kategori ini.'),
            )
          else
            for (final product in products)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 20, right: 16),
                title: Text(product.name),
                subtitle: Text(product.code),
              ),
        ],
      ),
    );
  }
}
