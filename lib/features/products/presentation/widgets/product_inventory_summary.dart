import 'package:flutter/material.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';

class ProductInventorySummary extends StatelessWidget {
  const ProductInventorySummary({required this.products, super.key});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final totalStock = products.fold<int>(
      0,
      (total, product) => total + product.currentStock,
    );
    final lowStock = products.where((product) => product.isLowStock).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _SummaryCard(
            label: 'Total products',
            value: '${products.length}',
            icon: Icons.inventory_2_outlined,
          ),
          _SummaryCard(
            label: 'Units in stock',
            value: '$totalStock',
            icon: Icons.warehouse_outlined,
          ),
          _SummaryCard(
            label: 'Low stock',
            value: '$lowStock',
            icon: Icons.warning_amber_rounded,
            isWarning: lowStock > 0,
          ),
        ];

        if (constraints.maxWidth < 620) {
          return SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, index) =>
                  SizedBox(width: 164, child: cards[index]),
            ),
          );
        }

        return Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = isWarning ? colors.error : colors.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
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
