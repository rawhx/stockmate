import 'package:flutter/material.dart';

class CategoryFormHeader extends StatelessWidget {
  const CategoryFormHeader({required this.isEditMode, super.key});

  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
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
                    isEditMode ? 'Perbarui kategori' : 'Buat kategori baru',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEditMode
                        ? 'Ubah nama dan deskripsi kategori.'
                        : 'Kelompokkan produk agar lebih mudah ditemukan dan dikelola.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
