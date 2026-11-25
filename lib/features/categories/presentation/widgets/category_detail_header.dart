import 'package:flutter/material.dart';

import '../../domain/entities/category_entity.dart';

class CategoryDetailHeader extends StatelessWidget {
  const CategoryDetailHeader({
    required this.category,
    required this.parentCategory,
    super.key,
  });

  final CategoryEntity category;
  final CategoryEntity? parentCategory;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.folder_outlined),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            if (parentCategory != null) ...[
              const SizedBox(height: 12),
              Chip(
                avatar: const Icon(Icons.folder_open_outlined),
                label: Text('Bagian dari ${parentCategory!.name}'),
                visualDensity: VisualDensity.compact,
              ),
            ],
            const SizedBox(height: 16),
            Text('Deskripsi', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              category.description?.isNotEmpty == true
                  ? category.description!
                  : 'Tidak ada deskripsi',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
