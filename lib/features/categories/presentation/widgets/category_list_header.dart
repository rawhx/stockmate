import 'package:flutter/material.dart';

class CategoryListHeader extends StatelessWidget {
  const CategoryListHeader({
    required this.totalCategories,
    required this.searchQuery,
    required this.onAddCategory,
    required this.onSearchChanged,
    required this.onClearSearch,
    super.key,
  });

  final int totalCategories;
  final String searchQuery;
  final VoidCallback onAddCategory;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: const Icon(Icons.category_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Kelompokkan barang agar mudah ditemukan.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Tambah kategori',
                  onPressed: onAddCategory,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(Icons.folder_copy_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalCategories',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Total kategori',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Cari kategori',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
