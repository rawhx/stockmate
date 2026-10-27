import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';
import 'package:stockmate/features/products/presentation/widgets/product_collection.dart';
import 'package:stockmate/features/products/presentation/widgets/product_inventory_summary.dart';
import 'package:stockmate/features/products/presentation/widgets/product_list_app_bar.dart';
import 'package:stockmate/features/products/presentation/widgets/product_list_header.dart';
import 'package:stockmate/features/products/presentation/widgets/product_list_states.dart';
import 'package:stockmate/features/products/presentation/widgets/product_list_toolbar.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({this.showAppActions = true, super.key});

  final bool showAppActions;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _searchController = TextEditingController();
  String _query = '';
  ProductStockFilter _stockFilter = ProductStockFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = _query.trim().toLowerCase();

    return products.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.code.toLowerCase().contains(query) ||
          product.categoryName.toLowerCase().contains(query);
      final matchesStock = switch (_stockFilter) {
        ProductStockFilter.all => true,
        ProductStockFilter.inStock => !product.isLowStock,
        ProductStockFilter.lowStock => product.isLowStock,
      };

      return matchesQuery && matchesStock;
    }).toList();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _stockFilter = ProductStockFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.products;
    final visibleProducts = _filterProducts(products);

    return Scaffold(
      appBar: ProductListAppBar(showActions: widget.showAppActions),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.fetchProducts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProductInventorySummary(products: products),
                          const SizedBox(height: 20),
                          ProductListToolbar(
                            controller: _searchController,
                            filter: _stockFilter,
                            onSearchChanged: (value) {
                              setState(() => _query = value);
                            },
                            onFilterChanged: (value) {
                              setState(() => _stockFilter = value);
                            },
                          ),
                          const SizedBox(height: 18),
                          ProductListHeader(itemCount: visibleProducts.length),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (provider.isLoading && products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.errorMessage != null && products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ProductErrorState(
                    message: provider.errorMessage!,
                    onRetry: provider.fetchProducts,
                  ),
                )
              else if (visibleProducts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ProductEmptyState(
                    hasFilters:
                        _query.isNotEmpty ||
                        _stockFilter != ProductStockFilter.all,
                    onClearFilters: _clearFilters,
                  ),
                )
              else
                ProductCollection(products: visibleProducts),
            ],
          ),
        ),
      ),
    );
  }
}
