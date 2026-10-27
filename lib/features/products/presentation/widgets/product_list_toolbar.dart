import 'package:flutter/material.dart';

enum ProductStockFilter { all, inStock, lowStock }

class ProductListToolbar extends StatelessWidget {
  const ProductListToolbar({
    required this.controller,
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    super.key,
  });

  final TextEditingController controller;
  final ProductStockFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ProductStockFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          key: const Key('product_search'),
          controller: controller,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search name, SKU, or category',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        );
        final stockFilter = DropdownButtonFormField<ProductStockFilter>(
          key: const Key('product_stock_filter'),
          initialValue: filter,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.tune)),
          items: const [
            DropdownMenuItem(
              value: ProductStockFilter.all,
              child: Text('All stock'),
            ),
            DropdownMenuItem(
              value: ProductStockFilter.inStock,
              child: Text('In stock'),
            ),
            DropdownMenuItem(
              value: ProductStockFilter.lowStock,
              child: Text('Low stock'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onFilterChanged(value);
          },
        );

        if (constraints.maxWidth < 620) {
          return Column(
            children: [search, const SizedBox(height: 12), stockFilter],
          );
        }

        return Row(
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: 12),
            Expanded(child: stockFilter),
          ],
        );
      },
    );
  }
}
