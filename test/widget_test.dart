import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stockmate/app/app.dart';
import 'package:stockmate/app/providers/app_providers.dart';
import 'package:stockmate/features/auth/domain/entities/auth_user.dart';
import 'package:stockmate/features/auth/domain/entities/sign_up_result.dart';
import 'package:stockmate/features/auth/domain/errors/auth_failure.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeAuthRepository repository,
  ) async {
    await tester.pumpWidget(
      AppProviders(authRepository: repository, child: const StockMateApp()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillRegistrationForm(WidgetTester tester) async {
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('register_full_name')),
      'Stock Mate',
    );
    await tester.enterText(
      find.byKey(const Key('register_email')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password')),
      'password',
    );
  }

  testWidgets('unauthenticated app shows the login page', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
  });

  testWidgets('restored session shows the protected root page', (tester) async {
    final repository = FakeAuthRepository(
      currentUser: const AuthUser(id: 'user-id', email: 'user@example.com'),
    );
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);

    expect(find.text('Products'), findsOneWidget);
    expect(find.byTooltip('Sign out'), findsOneWidget);
  });

  testWidgets('selecting a product opens its detail page', (tester) async {
    final repository = FakeAuthRepository(
      currentUser: const AuthUser(id: 'user-id', email: 'user@example.com'),
    );
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);
    await tester.tap(find.text('Beras Premium'));
    await tester.pumpAndSettle();

    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('Beras Premium'), findsOneWidget);
    expect(find.text('Product information'), findsOneWidget);
  });

  testWidgets('login validates required email and password', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('successful login opens the protected root page', (tester) async {
    const user = AuthUser(id: 'user-id', email: 'user@example.com');
    final repository = FakeAuthRepository()..signInResult = user;
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);
    await tester.enterText(find.byKey(const Key('login_email')), user.email);
    await tester.enterText(find.byKey(const Key('login_password')), 'password');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsOneWidget);
  });

  testWidgets('invalid login shows a friendly error and stays on login', (
    tester,
  ) async {
    final repository = FakeAuthRepository()
      ..signInError = const AuthFailure('The email or password is incorrect.');
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('register validates password confirmation', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);
    await fillRegistrationForm(tester);
    await tester.enterText(
      find.byKey(const Key('register_confirm_password')),
      'different',
    );
    final submit = find.byKey(const Key('register_submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('registration with confirmation returns to login with message', (
    tester,
  ) async {
    final repository = FakeAuthRepository()
      ..signUpResult = const SignUpResult(
        user: AuthUser(id: 'user-id', email: 'user@example.com'),
        requiresEmailConfirmation: true,
      );
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);
    await fillRegistrationForm(tester);
    await tester.enterText(
      find.byKey(const Key('register_confirm_password')),
      'password',
    );
    final submit = find.byKey(const Key('register_submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text(
        'Account created. Please check your email to verify your account.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('registration with a session opens the protected root page', (
    tester,
  ) async {
    final repository = FakeAuthRepository()
      ..signUpResult = const SignUpResult(
        user: AuthUser(id: 'user-id', email: 'user@example.com'),
        requiresEmailConfirmation: false,
      );
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);
    await fillRegistrationForm(tester);
    await tester.enterText(
      find.byKey(const Key('register_confirm_password')),
      'password',
    );
    final submit = find.byKey(const Key('register_submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsOneWidget);
  });

  testWidgets('protected location redirects unauthenticated user to login', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);
    final context = tester.element(find.text('Welcome back'));
    GoRouter.of(context).go('/products');
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Halaman tidak ditemukan'), findsNothing);
  });

  testWidgets('logout returns an authenticated user to login', (tester) async {
    final repository = FakeAuthRepository(
      currentUser: const AuthUser(id: 'user-id', email: 'user@example.com'),
    );
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);
    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Products'), findsNothing);
  });
}
