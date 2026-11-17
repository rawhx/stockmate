import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';
import 'package:stockmate/features/products/presentation/widgets/product_detail_sections.dart';
import 'package:stockmate/features/products/presentation/widgets/product_detail_states.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({required this.productId, super.key});

  final String productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
  }

  @override
  void didUpdateWidget(covariant ProductDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await context.read<ProductProvider>().getProductById(
        widget.productId,
      );
      if (!mounted) return;
      setState(() => _product = product);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _product = null;
        _errorMessage = 'The product could not be loaded. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            onPressed: _isLoading || _isDeleting || _product == null
                ? null
                : _editProduct,
            tooltip: 'Edit product',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _isLoading || _isDeleting ? null : _loadProduct,
            tooltip: 'Refresh product',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Future<void> _editProduct() async {
    final product = _product;
    if (product == null) return;
    final updated = await context.push<bool>('/products/${product.id}/edit');
    if (updated == true && mounted) await _loadProduct();
  }

  Future<void> _deleteProduct() async {
    final product = _product;
    if (product == null || _isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Delete "${product.name}"? Products with stock transactions cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);
    final provider = context.read<ProductProvider>();
    final success = await provider.removeProduct(product.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);
    if (success) {
      context.go('/');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product deleted.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'The product could not be deleted.',
          ),
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading && _product == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ProductDetailErrorState(
        message: _errorMessage!,
        onRetry: _loadProduct,
      );
    }

    final product = _product;
    if (product == null) {
      return ProductNotFoundState(onRetry: _loadProduct);
    }

    return RefreshIndicator(
      onRefresh: _loadProduct,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProductDetailOverview(product: product),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final information = ProductInformationCard(
                        product: product,
                      );
                      final stock = ProductStockCard(product: product);

                      if (constraints.maxWidth < 760) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            information,
                            const SizedBox(height: 16),
                            stock,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: information),
                          const SizedBox(width: 16),
                          Expanded(child: stock),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const Key('product_delete'),
                    onPressed: _isLoading || _isDeleting
                        ? null
                        : _deleteProduct,
                    icon: _isDeleting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(_isDeleting ? 'Deleting...' : 'Delete product'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
