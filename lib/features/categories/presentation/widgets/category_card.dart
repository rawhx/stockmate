import 'package:flutter/material.dart';

import '../../domain/entities/category_entity.dart';

class CategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback onTap;
  final bool isSubcategory;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.isSubcategory = false,
  });

  @override
  Widget build(BuildContext context) {
    final description = category.description?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            isSubcategory
                ? Icons.subdirectory_arrow_right
                : Icons.folder_outlined,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description == null || description.isEmpty
              ? 'Tidak ada deskripsi'
              : description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
