import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/category_entity.dart';
import '../mock/category_products.dart';
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
    final visibleCategories = provider.filteredCategories;
    final matchingIds = visibleCategories
        .map((category) => category.id)
        .toSet();

    final rootCategories = categories
        .where(
          (category) =>
              category.parentId == null &&
              (matchingIds.contains(category.id) ||
                  visibleCategories.any(
                    (child) => child.parentId == category.id,
                  )),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Barang')),
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 400;

                            final title = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manajemen Kategori',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${provider.categories.length} kategori tersedia',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            );

                            final actions = Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => setState(
                                    () => _isEditMode = !_isEditMode,
                                  ),
                                  icon: Icon(
                                    _isEditMode
                                        ? Icons.check
                                        : Icons.edit_outlined,
                                  ),
                                  label: Text(
                                    _isEditMode ? 'Selesai' : 'Kelola',
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: widget.onAddCategory,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah'),
                                ),
                              ],
                            );

                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  title,
                                  const SizedBox(height: 12),
                                  actions,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: title),
                                const SizedBox(width: 12),
                                actions,
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          onChanged: provider.setSearchQuery,
                          decoration: const InputDecoration(
                            hintText: 'Cari kategori...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
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
                else if (visibleCategories.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        provider.searchQuery.isEmpty
                            ? 'Belum ada kategori'
                            : 'Kategori tidak ditemukan',
                      ),
                    ),
                  )
                else if (rootCategories.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Kategori tidak ditemukan')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        for (final category in rootCategories)
                          _buildCategoryGroup(category),
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

  Widget _buildCategoryGroup(CategoryEntity category) {
    final provider = context.read<CategoryProvider>();
    final allChildren = provider.categories
        .where((item) => item.parentId == category.id)
        .toList();
    final query = provider.searchQuery.trim().toLowerCase();
    final children =
        query.isEmpty || category.name.toLowerCase().contains(query)
        ? allChildren
        : allChildren
              .where((item) => item.name.toLowerCase().contains(query))
              .toList();

    return _buildCategoryTile(
      category,
      isSubcategory: false,
      subcategories: children,
      initiallyExpanded: query.isNotEmpty,
    );
  }

  Widget _buildCategoryTile(
    CategoryEntity category, {
    required bool isSubcategory,
    List<CategoryEntity> subcategories = const [],
    bool initiallyExpanded = false,
  }) {
    final productStore = CategoryProductMockStore.instance;

    return ListenableBuilder(
      listenable: productStore,
      builder: (context, _) {
        final products = productStore.productsFor(category.id);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: Icon(
                isSubcategory
                    ? Icons.subdirectory_arrow_right
                    : Icons.folder_outlined,
                size: 19,
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isSubcategory
                  ? 'Subkategori | ${products.length} produk'
                  : '${subcategories.length} subkategori | ${products.length} produk',
            ),
            initiallyExpanded:
                _expandedCategories[category.id] ?? initiallyExpanded,
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
              // Subkategori berada di bagian atas isi kategori utama.
              for (final subcategory in subcategories)
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 8),
                  child: _buildCategoryTile(
                    subcategory,
                    isSubcategory: true,
                    initiallyExpanded: initiallyExpanded,
                  ),
                ),
              if (products.isNotEmpty)
                for (final product in products)
                  ListTile(
                    contentPadding: EdgeInsets.only(
                      left: isSubcategory ? 40 : 20,
                      right: 16,
                    ),
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(product.name),
                    subtitle: Text(product.code),
                  ),
              if (products.isEmpty && subcategories.isEmpty)
                const ListTile(
                  leading: Icon(Icons.inventory_2_outlined),
                  title: Text('Belum ada produk pada kategori ini.'),
                ),
            ],
          ),
        );
      },
    );
  }
}
