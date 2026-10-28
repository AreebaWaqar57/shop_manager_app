import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shop_manager/core/network/api_exception.dart';
import 'package:shop_manager/features/auth/providers/auth_provider.dart';
import 'package:shop_manager/features/auth/screens/login_screen.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late AuthProvider auth;

  Widget buildApp() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  setUp(() {
    repo = FakeAuthRepository();
    auth = AuthProvider(repo, FakeTokenStorage());
  });

  tearDown(() => auth.dispose());

  testWidgets('shows validation errors when the fields are empty',
          (tester) async {
        await tester.pumpWidget(buildApp());

        await tester.tap(find.text('Login'));
        await tester.pump();

        expect(find.text('Username is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
        expect(repo.loginCalls, 0);
      });

  testWidgets('calls login when the form is valid', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'demo');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(repo.loginCalls, 1);
    expect(auth.status, AuthStatus.authenticated);
  });

  testWidgets('shows the error message when login fails', (tester) async {
    repo.loginError = const ApiException(
      'Invalid credentials',
      statusCode: 400,
      type: ApiErrorType.badRequest,
    );
    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'demo');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
    expect(auth.status, isNot(AuthStatus.authenticated));
  });

  testWidgets('disables the button and shows a spinner while logging in',
          (tester) async {
        repo.gate = Completer<void>();
        await tester.pumpWidget(buildApp());

        await tester.enterText(find.byType(TextFormField).at(0), 'demo');
        await tester.enterText(find.byType(TextFormField).at(1), 'secret');
        await tester.tap(find.text('Login'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );

        repo.gate!.complete();
        await tester.pumpAndSettle();

        expect(repo.loginCalls, 1);
      });

  testWidgets('the eye icon toggles password visibility', (tester) async {
    await tester.pumpWidget(buildApp());

    TextField passwordField() =>
        tester.widget<TextField>(find.byType(TextField).at(1));

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    expect(passwordField().obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });
}