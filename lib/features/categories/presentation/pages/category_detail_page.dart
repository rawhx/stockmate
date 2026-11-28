import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/category_entity.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../widgets/category_detail_header.dart';
import '../widgets/category_product_picker_dialog.dart';
import '../widgets/category_products_section.dart';
import '../providers/category_provider.dart';
import '../widgets/subcategory_tile.dart';

class CategoryDetailPage extends StatelessWidget {
  final CategoryEntity initialCategory;
  String get categoryId => initialCategory.id;
  final VoidCallback onEdit;
  final VoidCallback onBack;
  final VoidCallback onAddSubcategory;
  final ValueChanged<String> onOpenSubcategory;

  const CategoryDetailPage({
    super.key,
    required this.initialCategory,
    required this.onEdit,
    required this.onBack,
    required this.onAddSubcategory,
    required this.onOpenSubcategory,
  });

  Future<void> _showSelectProduct(
    BuildContext context, {
    required String targetCategoryId,
    required String targetCategoryName,
  }) async {
    final productProvider = context.read<ProductProvider>();
    await productProvider.fetchProducts();

    if (!context.mounted) return;

    final selectedIds = await showDialog<Set<String>>(
      context: context,
      builder: (_) =>
          CategoryProductPickerDialog(categoryName: targetCategoryName),
    );

    if (selectedIds == null || selectedIds.isEmpty || !context.mounted) {
      return;
    }

    final moved = await productProvider.changeProductCategory(
      selectedIds,
      targetCategoryId,
    );

    if (!context.mounted) return;
    final failed = selectedIds.length - moved;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? '$moved produk berhasil ditambahkan ke kategori'
              : '$moved produk berhasil, $failed gagal ditambahkan ke kategori.',
        ),
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    CategoryProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text('Apakah kamu yakin ingin menghapus kategori ini?'),
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

    if (confirmed != true || !context.mounted) return;

    final success = await provider.removeCategory(categoryId);

    if (!context.mounted) return;

    if (success) {
      onBack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menghapus kategori'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    CategoryEntity? category;
    for (final item in provider.categories) {
      if (item.id == categoryId) {
        category = item;
        break;
      }
    }

    final selectedCategory = category ?? initialCategory;

    final subcategories = provider.categories
        .where((item) => item.parentId == categoryId)
        .toList();
    final products = context
        .watch<ProductProvider>()
        .products
        .where((product) => product.categoryId == categoryId)
        .toList();
    CategoryEntity? parentCategory;
    if (selectedCategory.parentId != null) {
      for (final item in provider.categories) {
        if (item.id == selectedCategory.parentId) {
          parentCategory = item;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali ke Daftar Kategori',
          onPressed: onBack,
        ),
        title: const Text('Detail Kategori'),
        actions: [
          IconButton(
            tooltip: 'Edit kategori',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Hapus kategori',
            onPressed: () => _deleteCategory(context, provider),
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSelectProduct(
          context,
          targetCategoryId: selectedCategory.id,
          targetCategoryName: selectedCategory.name,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            children: [
              CategoryDetailHeader(
                category: selectedCategory,
                parentCategory: parentCategory,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Subkategori',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAddSubcategory,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
              if (subcategories.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.account_tree_outlined),
                    title: Text('Belum ada subkategori.'),
                  ),
                )
              else ...[
                const SizedBox(height: 8),
                for (final subcategory in subcategories)
                  SubcategoryTile(
                    category: subcategory,
                    products: context
                        .read<ProductProvider>()
                        .products
                        .where(
                          (product) => product.categoryId == subcategory.id,
                        )
                        .toList(),
                    onOpen: () => onOpenSubcategory(subcategory.id),
                    onAddProduct: () => _showSelectProduct(
                      context,
                      targetCategoryId: subcategory.id,
                      targetCategoryName: subcategory.name,
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              CategoryProductsSection(products: products),
            ],
          ),
        ),
      ),
    );
  }
}
