import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/category_entity.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/category_provider.dart';

class CategoryDetailPage extends StatelessWidget {
  final String categoryId;
  final VoidCallback onEdit;
  final VoidCallback onBack;
  final VoidCallback onAddSubcategory;
  final ValueChanged<String> onOpenSubcategory;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
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

    final selectedProduct = await showDialog<Product>(
      context: context,
      builder: (dialogContext) {
        var query = '';
        Product? selected;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final products = productProvider.products.where((product) {
              final normalizedQuery = query.trim().toLowerCase();
              return normalizedQuery.isEmpty ||
                  product.name.toLowerCase().contains(normalizedQuery) ||
                  product.code.toLowerCase().contains(normalizedQuery);
            }).toList();

            return AlertDialog(
              title: Text('Pilih Produk untuk $targetCategoryName'),
              content: SizedBox(
                width: 500,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Cari produk atau kode',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setDialogState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: products.isEmpty
                          ? const Center(child: Text('Produk tidak ditemukan.'))
                          : RadioGroup<Product>(
                              groupValue: selected,
                              onChanged: (value) =>
                                  setDialogState(() => selected = value),
                              child: ListView.builder(
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  final currentCategory =
                                      product.categoryName.trim().isEmpty
                                      ? 'Belum memiliki kategori'
                                      : product.categoryName;

                                  return RadioListTile<Product>(
                                    value: product,
                                    title: Text(product.name),
                                    subtitle: Text(
                                      '${product.code} • Saat ini: $currentCategory',
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton.icon(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(dialogContext, selected),
                  icon: const Icon(Icons.link),
                  label: const Text('Tambahkan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedProduct == null || !context.mounted) return;

    final updatedProduct = selectedProduct.copyWith(
      categoryId: targetCategoryId,
      categoryName: targetCategoryName,
    );
    final success = await productProvider.editProduct(updatedProduct);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Produk berhasil ditambahkan ke kategori'
              : productProvider.errorMessage ?? 'Gagal menambahkan produk',
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

    final selectedCategory = category;
    if (selectedCategory == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali ke Daftar Kategori',
            onPressed: onBack,
          ),
          title: const Text('Detail Kategori'),
        ),

        body: const Center(child: Text('Kategori tidak ditemukan')),
      );
    }

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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            child: const Icon(Icons.folder_outlined),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              selectedCategory.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      if (parentCategory != null) ...[
                        const SizedBox(height: 12),
                        Chip(
                          avatar: const Icon(Icons.folder_open_outlined),
                          label: Text('Bagian dari ${parentCategory.name}'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Deskripsi',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selectedCategory.description?.isNotEmpty == true
                            ? selectedCategory.description!
                            : 'Tidak ada deskripsi',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
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
                  _buildSubcategoryTile(context, subcategory),
              ],
              const SizedBox(height: 24),
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
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoryTile(
    BuildContext context,
    CategoryEntity subcategory,
  ) {
    var isExpanded = false;

    return StatefulBuilder(
      builder: (tileContext, setTileState) {
        final subcategoryProducts = context
            .watch<ProductProvider>()
            .products
            .where((product) => product.categoryId == subcategory.id)
            .toList();

        return Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: const Icon(Icons.subdirectory_arrow_right),
            title: Text(subcategory.name),
            subtitle: Text('${subcategoryProducts.length} produk'),
            onExpansionChanged: (expanded) =>
                setTileState(() => isExpanded = expanded),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Lihat detail ${subcategory.name}',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.open_in_new_outlined, size: 19),
                  onPressed: () => onOpenSubcategory(subcategory.id),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            children: [
              ...subcategoryProducts.map(
                (product) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 56, right: 16),
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.code}  |  Rp ${product.price.toStringAsFixed(0)}',
                  ),
                ),
              ),
              if (subcategoryProducts.isEmpty)
                const ListTile(
                  contentPadding: EdgeInsets.only(left: 56, right: 16),
                  title: Text('Belum ada produk pada subkategori ini.'),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 48, bottom: 8),
                  child: TextButton.icon(
                    onPressed: () => _showSelectProduct(
                      context,
                      targetCategoryId: subcategory.id,
                      targetCategoryName: subcategory.name,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah produk'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
