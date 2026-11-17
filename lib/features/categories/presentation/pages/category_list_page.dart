import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';

import '../../domain/entities/category_entity.dart';
import '../providers/category_provider.dart';
import '../widgets/category_app_bar.dart';
import '../widgets/category_list_header.dart';
import '../widgets/category_tile.dart';

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
      appBar: CategoryAppBar(
        isEditMode: _isEditMode,
        onToggleEditMode: () => setState(() => _isEditMode = !_isEditMode),
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
                    child: CategoryListHeader(
                      totalCategories: provider.categories
                          .where((item) => item.parentId == null)
                          .length,
                      searchQuery: provider.searchQuery,
                      onAddCategory: widget.onAddCategory,
                      onSearchChanged: provider.setSearchQuery,
                      onClearSearch: () => provider.setSearchQuery(''),
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
                          CategoryTile(
                            category: category,
                            products: context
                                .read<ProductProvider>()
                                .products
                                .where(
                                  (product) =>
                                      product.categoryId == category.id,
                                )
                                .toList(),
                            isEditMode: _isEditMode,
                            isExpanded:
                                _expandedCategories[category.id] ?? false,
                            onExpanded: (expanded) => setState(
                              () => _expandedCategories[category.id] = expanded,
                            ),
                            onOpen: () => widget.onOpenDetail(category.id),
                            onEdit: () => widget.onEditCategory(category.id),
                            onDelete: () => _deleteCategory(category),
                          ),
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
}
