import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/category_entity.dart';
import '../providers/category_provider.dart';

class CategoryRouteLoader extends StatefulWidget {
  const CategoryRouteLoader({
    required this.categoryId,
    required this.builder,
    required this.onBack,
    this.loadChildren = false,
    super.key,
  });

  final String categoryId;
  final Widget Function(CategoryEntity) builder;
  final VoidCallback onBack;
  final bool loadChildren;

  @override
  State<CategoryRouteLoader> createState() => _CategoryRouteLoaderState();
}

class _CategoryRouteLoaderState extends State<CategoryRouteLoader> {
  late Future<CategoryEntity?> _request;

  @override
  void initState() {
    super.initState();
    _request = _load();
  }

  Future<CategoryEntity?> _load() async {
    final provider = context.read<CategoryProvider>();
    if (widget.loadChildren) {
      await Future<void>.microtask(provider.loadCategories);
    }
    if (!mounted) return null;
    return provider.getCategory(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CategoryEntity?>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final category = snapshot.data;
        if (category != null) return widget.builder(category);
        return Scaffold(
          appBar: AppBar(title: const Text('Kategori')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.hasError
                        ? 'Gagal memuat kategori.'
                        : 'Kategori tidak ditemukan.',
                  ),
                  TextButton(
                    onPressed: () => setState(() => _request = _load()),
                    child: const Text('Coba lagi'),
                  ),
                  TextButton(
                    onPressed: widget.onBack,
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
