import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/category_entity.dart';
import '../providers/category_provider.dart';

class CategoryFormPage extends StatefulWidget {
  final String? categoryId;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  const CategoryFormPage({
    super.key,
    this.categoryId,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _parentId;
  CategoryEntity? _originalCategory;
  bool _initialized = false;
  bool _isSaving = false;

  bool get isEditMode => widget.categoryId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    if (isEditMode) {
      final categories = context.read<CategoryProvider>().categories;

      for (final category in categories) {
        if (category.id == widget.categoryId) {
          _originalCategory = category;
          _nameController.text = category.name;
          _descriptionController.text = category.description ?? '';
          _parentId = category.parentId;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final provider = context.read<CategoryProvider>();
    final now = DateTime.now();

    final CategoryEntity category;

    if (isEditMode) {
      final original = _originalCategory;

      if (original == null) {
        setState(() => _isSaving = false);
        return;
      }

      category = CategoryEntity(
        id: original.id,
        ownerId: original.ownerId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        parentId: _parentId,
        createdAt: original.createdAt,
        updatedAt: now,
      );
    } else {
      category = CategoryEntity(
        id: 'CAT-${now.microsecondsSinceEpoch}',
        ownerId: 'dummy-user',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        parentId: _parentId,
        createdAt: now,
        updatedAt: now,
      );
    }

    final success = isEditMode
        ? await provider.editCategory(category)
        : await provider.createCategory(category);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan kategori'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    final parentOptions = categories
        .where(
          (category) =>
              category.id != widget.categoryId && category.parentId == null,
        )
        .toList();

    if (isEditMode && _originalCategory == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Kategori')),
        body: const Center(child: Text('Kategori tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali tanpa menyimpan',
          onPressed: _isSaving ? null : widget.onCancel,
        ),
        title: Text(isEditMode ? 'Edit Kategori' : 'Tambah Kategori'),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            child: Icon(
                              isEditMode
                                  ? Icons.edit_outlined
                                  : Icons.create_new_folder_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditMode
                                      ? 'Perbarui kategori'
                                      : 'Buat kategori baru',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isEditMode
                                      ? 'Ubah nama, deskripsi, atau kategori utamanya.'
                                      : 'Kelompokkan produk agar lebih mudah ditemukan dan dikelola.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Informasi kategori',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            maxLength: 80,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nama kategori *',
                              hintText: 'Contoh: Elektronik',
                              helperText: 'Nama kategori wajib diisi.',
                              prefixIcon: Icon(Icons.folder_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama kategori wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            maxLength: 240,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Deskripsi (opsional)',
                              hintText: 'Jelaskan isi atau kegunaan kategori',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _parentId ?? '',
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Kategori utama (opsional)',
                              helperText:
                                  'Pilih kategori utama jika ini subkategori.',
                              prefixIcon: Icon(Icons.account_tree_outlined),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Jadikan kategori utama'),
                              ),
                              ...parentOptions.map(
                                (category) => DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Text(
                                    category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _parentId = value == null || value.isEmpty
                                    ? null
                                    : value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final saveButton = FilledButton.icon(
                        onPressed: _isSaving ? null : _saveCategory,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _isSaving
                              ? 'Menyimpan...'
                              : isEditMode
                              ? 'Simpan perubahan'
                              : 'Simpan kategori',
                        ),
                      );
                      final cancelButton = OutlinedButton(
                        onPressed: _isSaving ? null : widget.onCancel,
                        child: const Text('Batal'),
                      );

                      if (constraints.maxWidth < 380) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            saveButton,
                            const SizedBox(height: 8),
                            cancelButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cancelButton),
                          const SizedBox(width: 12),
                          Expanded(child: saveButton),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
