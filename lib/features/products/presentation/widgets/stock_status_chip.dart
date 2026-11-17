import 'package:flutter/material.dart';

class StockStatusChip extends StatelessWidget {
  const StockStatusChip({
    required this.currentStock,
    required this.minimumStock,
    this.compact = false,
    super.key,
  });

  final int currentStock;
  final int minimumStock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLowStock = currentStock <= minimumStock;
    final colors = Theme.of(context).colorScheme;
    final foreground = isLowStock ? colors.error : colors.primary;
    final background = foreground.withValues(alpha: 0.1);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLowStock
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            size: compact ? 14 : 16,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            isLowStock ? 'Low' : 'In stock',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
