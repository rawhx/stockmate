import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/category_entity.dart';
import '../mock/category_products.dart';
import '../providers/category_provider.dart';

class CategoryDetailPage extends StatelessWidget {
  final String categoryId;
  final VoidCallback onEdit;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenSubcategory;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
    required this.onEdit,
    required this.onBack,
    required this.onOpenSubcategory,
  });

  Future<void> _showAddProduct(
    BuildContext context, {
    required String targetCategoryId,
    required String targetCategoryName,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final priceController = TextEditingController();

    try {
      final product = await showDialog<CategoryProduct>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Tambah Produk ke $targetCategoryName'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama produk',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama produk wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Kode produk',
                      prefixIcon: Icon(Icons.qr_code_2_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Kode produk wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Harga',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) {
                      final price = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );
                      if (price == null || price <= 0) {
                        return 'Masukkan harga lebih dari 0';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  dialogContext,
                  CategoryProduct(
                    code: codeController.text.trim(),
                    name: nameController.text.trim(),
                    price: double.parse(
                      priceController.text.trim().replaceAll(',', '.'),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ],
        ),
      );

      if (product == null || !context.mounted) return;
      CategoryProductMockStore.instance.addProduct(targetCategoryId, product);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil ditambahkan')),
      );
    } finally {
      nameController.dispose();
      codeController.dispose();
      priceController.dispose();
    }
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProduct(
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
          child: ListenableBuilder(
            listenable: CategoryProductMockStore.instance,
            builder: (context, _) {
              final products = CategoryProductMockStore.instance.productsFor(
                selectedCategory.id,
              );

              return ListView(
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
                                  selectedCategory.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
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
                  if (subcategories.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Subkategori',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
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
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Text(product.code),
                          trailing: Text(
                            'Rp ${product.price.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteCategory(context, provider),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Hapus'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
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
        final subcategoryProducts = CategoryProductMockStore.instance
            .productsFor(subcategory.id);

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
                    onPressed: () => _showAddProduct(
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
