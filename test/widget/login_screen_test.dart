import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/screens/auth/login_screen.dart';
import 'package:padelhub/screens/auth/signup_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('should display all UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Check if all main elements are present
      expect(find.text('PadelHub'), findsOneWidget);
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      
      // Check for icons
      expect(find.byIcon(Icons.sports_tennis), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });

    testWidgets('should show validation error for empty email',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Tap login button without entering data
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Enter invalid email
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'invalidemail');

      // Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should show validation error for empty password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Enter email but not password
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      // Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should show validation error for short password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Enter email and short password
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, '12345');

      // Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should toggle password visibility',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find password field - need to find the TextField inside TextFormField
      final passwordFieldFinder = find.ancestor(
        of: find.text('Password'),
        matching: find.byType(TextFormField),
      );

      // Initially password should be obscured
      final initialTextField = find.descendant(
        of: passwordFieldFinder,
        matching: find.byType(TextField),
      );
      expect(
        tester.widget<TextField>(initialTextField).obscureText,
        true,
      );

      // Tap visibility toggle
      final visibilityToggle = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Password should now be visible
      final updatedTextField = find.descendant(
        of: passwordFieldFinder,
        matching: find.byType(TextField),
      );
      expect(
        tester.widget<TextField>(updatedTextField).obscureText,
        false,
      );

      // Check that icon changed
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('should navigate to SignupScreen when Sign Up is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find and tap the Sign Up link
      final signUpLink = find.text('Sign Up');
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      // Verify navigation to SignupScreen
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });
  });
}
