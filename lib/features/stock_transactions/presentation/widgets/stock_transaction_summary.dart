import 'package:flutter/material.dart';

class StockTransactionSummary extends StatelessWidget {
  const StockTransactionSummary({
    required this.totalCount,
    required this.totalIn,
    required this.totalOut,
    super.key,
  });

  final int totalCount;
  final int totalIn;
  final int totalOut;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total',
                  value: '$totalCount',
                  icon: Icons.receipt_long_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  title: 'Masuk',
                  value: '+$totalIn',
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  title: 'Keluar',
                  value: '-$totalOut',
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFC62828),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Transaksi',
                value: '$totalCount Catatan',
                icon: Icons.receipt_long_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Total Stok Masuk',
                value: '+$totalIn Item',
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Total Stok Keluar',
                value: '-$totalOut Item',
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFC62828),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withAlpha(30),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
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
