import 'package:flutter/material.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';
import 'package:stockmate/features/products/presentation/widgets/stock_status_chip.dart';

class ProductDetailOverview extends StatelessWidget {
  const ProductDetailOverview({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final identity = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 32,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.code} • ${product.categoryName}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                      StockStatusChip(
                        currentStock: product.currentStock,
                        minimumStock: product.minimumStock,
                      ),
                    ],
                  ),
                ),
              ],
            );
            final price = Column(
              crossAxisAlignment: constraints.maxWidth < 620
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  'Selling price',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRupiah(product.price),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            );

            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  price,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: identity),
                const SizedBox(width: 24),
                price,
              ],
            );
          },
        ),
      ),
    );
  }
}

class ProductInformationCard extends StatelessWidget {
  const ProductInformationCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Product information',
      icon: Icons.description_outlined,
      children: [
        _DetailRow(label: 'Product code', value: product.code),
        _DetailRow(label: 'Category', value: product.categoryName),
        _DetailRow(label: 'Unit', value: product.unit),
        _DetailRow(
          label: 'Supplier',
          value: product.supplierName ?? 'No supplier assigned',
          showDivider: false,
        ),
      ],
    );
  }
}

class ProductStockCard extends StatelessWidget {
  const ProductStockCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = product.isLowStock ? colors.error : colors.primary;
    final target = product.minimumStock > 0 ? product.minimumStock * 2 : 1;
    final progress = (product.currentStock / target).clamp(0.0, 1.0);

    return _DetailCard(
      title: 'Stock overview',
      icon: Icons.warehouse_outlined,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${product.currentStock}',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(color: statusColor, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                product.unit,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: statusColor,
            backgroundColor: statusColor.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(height: 12),
        _DetailRow(
          label: 'Minimum stock',
          value: '${product.minimumStock} ${product.unit}',
          showDivider: false,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                product.isLowStock
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                size: 20,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.isLowStock
                      ? 'Stock is at or below the minimum level.'
                      : 'Stock level is currently healthy.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: colors.outlineVariant),
      ],
    );
  }
}

String _formatRupiah(double value) {
  final digits = value.round().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $formatted';
}
