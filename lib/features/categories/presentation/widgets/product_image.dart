import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.productName,
    this.imageUrl = '',
    this.size = 48,
  });

  final String productName;
  final String? imageUrl;
  final double size;

  String get _resolvedImageUrl {
    final explicitImageUrl = imageUrl?.trim();
    if (explicitImageUrl != null && explicitImageUrl.isNotEmpty) {
      return explicitImageUrl;
    }

    final name = productName.toLowerCase();

    if (name.contains('pensil')) {
      return 'https://images.unsplash.com/photo-1516979187457-637abb4f9353?w=160&q=80';
    }
    if (name.contains('buku')) {
      return 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=160&q=80';
    }
    if (name.contains('tas')) {
      return 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=160&q=80';
    }
    if (name.contains('mouse')) {
      return 'https://images.unsplash.com/photo-1527814050087-3793815479db?w=160&q=80';
    }
    if (name.contains('keyboard')) {
      return 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=160&q=80';
    }
    if (name.contains('kursi')) {
      return 'https://images.unsplash.com/photo-1505843490701-5a442a4b4f64?w=160&q=80';
    }
    if (name.contains('kotak') || name.contains('penyimpanan')) {
      return 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=160&q=80';
    }
    return 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=160&q=80';
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        _resolvedImageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
      ),
    );
  }
}
