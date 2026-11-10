import 'package:flutter/material.dart';

class ProductDetailErrorState extends StatelessWidget {
  const ProductDetailErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _ProductDetailState(
      icon: Icons.cloud_off_outlined,
      title: 'Could not load product',
      message: message,
      actionLabel: 'Try again',
      onPressed: onRetry,
    );
  }
}

class ProductNotFoundState extends StatelessWidget {
  const ProductNotFoundState({required this.onRetry, super.key});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _ProductDetailState(
      icon: Icons.inventory_2_outlined,
      title: 'Product not found',
      message: 'This product may have been removed or is no longer available.',
      actionLabel: 'Refresh',
      onPressed: onRetry,
    );
  }
}

class _ProductDetailState extends StatelessWidget {
  const _ProductDetailState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
