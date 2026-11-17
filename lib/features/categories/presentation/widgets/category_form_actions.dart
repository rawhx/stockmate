import 'package:flutter/material.dart';

class CategoryFormActions extends StatelessWidget {
  const CategoryFormActions({
    required this.isEditMode,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final bool isEditMode;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final saveButton = FilledButton.icon(
          onPressed: isSaving ? null : onSave,
          icon: isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(
            isSaving
                ? 'Menyimpan...'
                : isEditMode
                ? 'Simpan perubahan'
                : 'Simpan kategori',
          ),
        );
        final cancelButton = OutlinedButton(
          onPressed: isSaving ? null : onCancel,
          child: const Text('Batal'),
        );

        if (constraints.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [saveButton, const SizedBox(height: 8), cancelButton],
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
    );
  }
}
