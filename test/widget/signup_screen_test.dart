import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/screens/auth/signup_screen.dart';

void main() {
  group('SignupScreen Widget Tests', () {
    testWidgets('should display all UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      // Check if all main elements are present
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Join the padel community!'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Sign Up'), findsAtLeastNWidgets(1));
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      
      // Check for icons
      expect(find.byIcon(Icons.sports_tennis), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsAtLeastNWidgets(2));
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('should show validation error for empty email',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      // Tap sign up button without entering data
      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      // Enter invalid email
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'invalidemail');

      // Tap sign up button
      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should show validation error for empty password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      // Enter email but not password
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      // Tap sign up button
      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('should show validation error for short password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      // Enter email and short password
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      final passwordFields = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordFields, '12345');

      // Tap sign up button
      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should show validation error when passwords do not match',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      // Enter email
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      // Enter password
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'password123');

      // Enter different confirm password
      final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirm Password');
      await tester.enterText(confirmPasswordField, 'password456');

      // Tap sign up button
      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Check for validation error
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should toggle password visibility on both fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      // Find password field TextFields
      final passwordFieldFinder = find.ancestor(
        of: find.text('Password'),
        matching: find.byType(TextFormField),
      );
      final confirmPasswordFieldFinder = find.ancestor(
        of: find.text('Confirm Password'),
        matching: find.byType(TextFormField),
      );

      // Initially passwords should be obscured
      final passwordTextField = find.descendant(
        of: passwordFieldFinder,
        matching: find.byType(TextField),
      );
      final confirmPasswordTextField = find.descendant(
        of: confirmPasswordFieldFinder,
        matching: find.byType(TextField),
      );

      expect(tester.widget<TextField>(passwordTextField).obscureText, true);
      expect(tester.widget<TextField>(confirmPasswordTextField).obscureText, true);

      // Find visibility toggles
      final visibilityToggles = find.byIcon(Icons.visibility_outlined);
      
      // Tap first password visibility toggle
      await tester.tap(visibilityToggles.first);
      await tester.pumpAndSettle();

      // First password should now be visible
      final updatedPasswordTextField = find.descendant(
        of: passwordFieldFinder,
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(updatedPasswordTextField).obscureText, false);

      // Tap second password visibility toggle
      await tester.tap(visibilityToggles.last);
      await tester.pumpAndSettle();

      // Second password should now be visible
      final updatedConfirmPasswordTextField = find.descendant(
        of: confirmPasswordFieldFinder,
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(updatedConfirmPasswordTextField).obscureText, false);
    });

    testWidgets('should navigate back when back button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: const Text('Go to Signup'),
              ),
            ),
          ),
        ),
      );

      // Navigate to signup screen
      await tester.tap(find.text('Go to Signup'));
      await tester.pumpAndSettle();

      // Verify we're on signup screen
      expect(find.text('Create Account'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pumpAndSettle();

      // Verify we're back to original screen
      expect(find.text('Go to Signup'), findsOneWidget);
      expect(find.text('Create Account'), findsNothing);
    });

    testWidgets('should navigate back when Log In is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: const Text('Go to Signup'),
              ),
            ),
          ),
        ),
      );

      // Navigate to signup screen
      await tester.tap(find.text('Go to Signup'));
      await tester.pumpAndSettle();

      // Tap Log In link
      final loginLink = find.text('Log In');
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      // Verify we're back to original screen
      expect(find.text('Go to Signup'), findsOneWidget);
    });
  });
}
