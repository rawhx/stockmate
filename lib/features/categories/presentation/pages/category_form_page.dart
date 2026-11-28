import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/category_entity.dart';
import '../providers/category_provider.dart';
import '../widgets/category_form_actions.dart';
import '../widgets/category_form_fields.dart';
import '../widgets/category_form_header.dart';

class CategoryFormPage extends StatefulWidget {
  final CategoryEntity? category;
  final String? parentId;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  const CategoryFormPage({
    super.key,
    this.category,
    this.parentId,
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

  bool _isSaving = false;

  bool get isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _parentId = category?.parentId ?? widget.parentId;
    _originalCategory = category;
    if (category != null) {
      _nameController.text = category.name;
      _descriptionController.text = category.description ?? '';
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
        id: '',
        ownerId: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
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
            child: Builder(
              builder: (context) {
                final categories = context.read<CategoryProvider>().categories;
                return Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CategoryFormHeader(isEditMode: isEditMode),
                      const SizedBox(height: 16),
                      CategoryFormFields(
                        nameController: _nameController,
                        descriptionController: _descriptionController,
                        existingCategories: categories,
                        currentCategoryId: _originalCategory?.id,
                      ),
                      const SizedBox(height: 16),
                      CategoryFormActions(
                        isEditMode: isEditMode,
                        isSaving: _isSaving,
                        onSave: _saveCategory,
                        onCancel: widget.onCancel,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
