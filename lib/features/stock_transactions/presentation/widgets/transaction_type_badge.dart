import 'package:flutter/material.dart';

import '../../domain/entities/transaction_type.dart';

class TransactionTypeBadge extends StatelessWidget {
  const TransactionTypeBadge({
    required this.type,
    this.isCompact = false,
    super.key,
  });

  final TransactionType type;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = type.isIn
        ? (isDark
              ? const Color(0xFF1B5E20).withAlpha(120)
              : const Color(0xFFE8F5E9))
        : (isDark
              ? const Color(0xFFB71C1C).withAlpha(120)
              : const Color(0xFFFFEBEE));

    final textColor = type.isIn
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFE57373) : const Color(0xFFC62828));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: isCompact ? 14 : 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
