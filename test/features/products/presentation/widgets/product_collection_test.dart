import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/app/theme/app_theme.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';
import 'package:stockmate/features/products/presentation/widgets/product_card.dart';
import 'package:stockmate/features/products/presentation/widgets/product_collection.dart';

const _product = Product(
  id: '1',
  code: 'PRD-EXTENDED-PACKAGE-001',
  name: 'Premium rice package with a long product name',
  price: 75000,
  unit: 'large carton package',
  categoryId: 'cat-1',
  categoryName: 'Food and groceries',
  minimumStock: 1,
  currentStock: 12345,
);

void main() {
  Future<void> pumpCollection(
    WidgetTester tester,
    double width,
    double scale,
  ) async {
    await tester.binding.setSurfaceSize(Size(width, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                ProductCollection(
                  products: List.generate(
                    4,
                    (index) => _product.copyWith(id: '$index'),
                  ),
                  onProductTap: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final width in [320.0, 390.0, 900.0, 1600.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'long product content fits width $width at text scale $scale',
        (tester) async {
          await pumpCollection(tester, width, scale);
          expect(find.byType(ProductCard), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('wide inventory rows stay centered within the toolbar width', (
    tester,
  ) async {
    await pumpCollection(tester, 1600, 1);
    final cards = find.byType(ProductCard);
    final first = tester.getRect(cards.at(0));
    final third = tester.getRect(cards.at(2));
    final fourth = tester.getRect(cards.at(3));
    expect(first.left, 200);
    expect(third.right, 1400);
    expect(fourth.left, first.left);
    expect(fourth.width, closeTo(first.width, 0.01));
    expect(fourth.top, greaterThan(first.bottom));
  });
}
