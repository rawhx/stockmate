import 'package:flutter/material.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';
import 'package:stockmate/features/products/presentation/widgets/product_card.dart';

class ProductCollection extends StatelessWidget {
  const ProductCollection({
    required this.products,
    required this.onProductTap,
    super.key,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.crossAxisExtent.clamp(0.0, 1200.0);
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final columnCount = textScale > 1.3 || contentWidth < 700
              ? 1
              : contentWidth >= 1100
              ? 3
              : 2;
          // Build lazy rows with natural height so larger text and wrapped
          // product codes cannot overflow a fixed grid cell.
          return SliverList.separated(
            itemCount: (products.length / columnCount).ceil(),
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, row) {
              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var column = 0; column < columnCount; column++) ...[
                        if (column > 0) const SizedBox(width: 16),
                        Expanded(
                          child: row * columnCount + column < products.length
                              ? ProductCard(
                                  product: products[row * columnCount + column],
                                  onTap: () => onProductTap(
                                    products[row * columnCount + column],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
