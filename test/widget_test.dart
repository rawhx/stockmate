import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/app/app.dart';
import 'package:stockmate/app/providers/app_providers.dart';

void main() {
  testWidgets('shows the application placeholder', (tester) async {
    await tester.pumpWidget(const AppProviders(child: StockMateApp()));
    await tester.pumpAndSettle();

    expect(find.text('StockMate'), findsOneWidget);
    expect(find.text('Boilerplate aplikasi siap'), findsOneWidget);
  });
}
