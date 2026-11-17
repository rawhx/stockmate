import 'package:flutter/material.dart';

class CategoryFormFields extends StatelessWidget {
  const CategoryFormFields({
    required this.nameController,
    required this.descriptionController,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return Card(
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
              controller: nameController,
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
              controller: descriptionController,
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
          ],
        ),
      ),
    );
  }
}
