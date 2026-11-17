import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';
import 'package:stockmate/features/products/presentation/widgets/product_list_app_bar.dart';

import '../../domain/entities/category_entity.dart';
import '../providers/category_provider.dart';

class CategoryListPage extends StatefulWidget {
  final ValueChanged<String> onOpenDetail;
  final ValueChanged<String> onEditCategory;
  final VoidCallback onAddCategory;

  const CategoryListPage({
    super.key,
    required this.onOpenDetail,
    required this.onEditCategory,
    required this.onAddCategory,
  });

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  bool _isEditMode = false;
  final Map<String, bool> _expandedCategories = {};
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<CategoryProvider>().loadCategories();
      context.read<ProductProvider>().fetchProducts();
    });
  }

  Future<void> _deleteCategory(CategoryEntity category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<CategoryProvider>();
    final success = await provider.removeCategory(category.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Kategori berhasil dihapus'
              : provider.errorMessage ?? 'Gagal menghapus kategori',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final categories = provider.categories;
    final query = provider.searchQuery.trim().toLowerCase();

    final rootCategories = categories
        .where(
          (category) =>
              category.parentId == null &&
              (query.isEmpty || category.name.toLowerCase().contains(query)),
        )
        .toList();

    return Scaffold(
      appBar: ProductListAppBar(
        title: 'Categories',
        subtitle: 'Manage your categories',
        showActions: true,
        additionalActions: [
          IconButton(
            tooltip: 'Kelola kategori',
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
            icon: Icon(_isEditMode ? Icons.check_rounded : Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  child: const Icon(Icons.category_rounded),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Manajemen Kategori',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Kelompokkan barang agar mudah ditemukan.',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton.filled(
                                  tooltip: 'Tambah kategori',
                                  onPressed: widget.onAddCategory,
                                  icon: const Icon(Icons.add_rounded),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                icon: Icons.folder_copy_outlined,
                                label: 'Total kategori',
                                value:
                                    '${provider.categories.where((item) => item.parentId == null).length}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: provider.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Cari kategori',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: provider.searchQuery.isNotEmpty
                                ? IconButton(
                                    tooltip: 'Hapus pencarian',
                                    onPressed: () =>
                                        provider.setSearchQuery(''),
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                : null,
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                if (provider.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: TextButton(
                        onPressed: provider.loadCategories,
                        child: const Text('Coba Lagi'),
                      ),
                    ),
                  )
                else if (rootCategories.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Belum ada kategori')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        for (final category in rootCategories)
                          _buildCategoryTile(category),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(CategoryEntity category) {
    final products = context
        .watch<ProductProvider>()
        .products
        .where((product) => product.categoryId == category.id)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: const Icon(Icons.folder_outlined, size: 19),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${products.length} produk'),
        initiallyExpanded: _expandedCategories[category.id] ?? false,
        onExpansionChanged: (expanded) {
          setState(() => _expandedCategories[category.id] = expanded);
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Lihat detail ${category.name}',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.open_in_new_outlined, size: 19),
              onPressed: () => widget.onOpenDetail(category.id),
            ),
            if (_isEditMode) ...[
              IconButton(
                tooltip: 'Edit ${category.name}',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => widget.onEditCategory(category.id),
              ),
              IconButton(
                tooltip: 'Hapus ${category.name}',
                visualDensity: VisualDensity.compact,
                color: Theme.of(context).colorScheme.error,
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deleteCategory(category),
              ),
            ],
            AnimatedRotation(
              turns: _expandedCategories[category.id] == true ? 0.25 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        children: [
          if (products.isNotEmpty)
            for (final product in products)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 20, right: 16),
                title: Text(product.name),
                subtitle: Text(product.code),
              ),
          if (products.isEmpty)
            const ListTile(
              leading: Icon(Icons.inventory_2_outlined),
              title: Text('Belum ada produk pada kategori ini.'),
            ),
        ],
      ),
    );
  }
}
