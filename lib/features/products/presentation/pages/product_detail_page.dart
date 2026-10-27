import 'package:flutter/material.dart';
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
            onPressed: _isLoading ? null : _loadProduct,
            tooltip: 'Refresh product',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
