import 'package:flutter/material.dart';

class CategoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CategoryAppBar({
    required this.isEditMode,
    required this.onToggleEditMode,
    super.key,
  });

  final bool isEditMode;
  final VoidCallback onToggleEditMode;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kategori Barang'),
          Text(
            'Manage your categories',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Kelola kategori',
          onPressed: onToggleEditMode,
          icon: Icon(isEditMode ? Icons.check_rounded : Icons.tune_rounded),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
