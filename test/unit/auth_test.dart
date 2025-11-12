import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  group('Firebase Authentication Unit Tests', () {
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth();
    });

    test('should create user with email and password', () async {
      final result = await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.user, isNotNull);
      expect(result.user?.email, 'test@example.com');
    });

    test('should sign in user with email and password', () async {
      // First create a user
      await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      // Sign out
      await mockAuth.signOut();

      // Sign in again
      final result = await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.user, isNotNull);
      expect(result.user?.email, 'test@example.com');
    });

    test('should sign out user', () async {
      // Create and sign in a user
      await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(mockAuth.currentUser, isNotNull);

      // Sign out
      await mockAuth.signOut();

      expect(mockAuth.currentUser, isNull);
    });

    test('should return current user when signed in', () async {
      await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      final currentUser = mockAuth.currentUser;

      expect(currentUser, isNotNull);
      expect(currentUser?.email, 'test@example.com');
    });

    test('should return null for current user when not signed in', () {
      final currentUser = mockAuth.currentUser;

      expect(currentUser, isNull);
    });

    test('should emit auth state changes', () async {
      final authStates = <dynamic>[];

      // Listen to auth state changes
      mockAuth.authStateChanges().listen((user) {
        authStates.add(user);
      });

      // Wait a bit for initial state
      await Future.delayed(const Duration(milliseconds: 100));

      // Create a user
      await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // Sign out
      await mockAuth.signOut();

      await Future.delayed(const Duration(milliseconds: 100));

      // Should have emitted at least one state change
      expect(authStates.length, greaterThan(0));
    });

    test('should handle multiple users with different emails', () async {
      final user1 = await mockAuth.createUserWithEmailAndPassword(
        email: 'user1@example.com',
        password: 'password123',
      );

      await mockAuth.signOut();

      final user2 = await mockAuth.createUserWithEmailAndPassword(
        email: 'user2@example.com',
        password: 'password456',
      );

      expect(user1.user?.email, 'user1@example.com');
      expect(user2.user?.email, 'user2@example.com');
      expect(user1.user?.email, isNot(equals(user2.user?.email)));
    });

    test('should maintain user session after creation', () async {
      await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      // User should still be signed in
      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser?.email, 'test@example.com');
    });
  });

  group('Email Validation Tests', () {
    test('should validate correct email formats', () {
      final validEmails = [
        'test@example.com',
        'user.name@example.co.uk',
        'user+tag@example.com',
        'user123@test-domain.com',
      ];

      for (final email in validEmails) {
        expect(email.contains('@'), isTrue, reason: '$email should be valid');
      }
    });

    test('should invalidate incorrect email formats', () {
      final invalidEmails = ['notanemail', 'missing@domain', 'no-at-sign.com'];

      for (final email in invalidEmails) {
        final isValid = email.contains('@') && email.contains('.');
        expect(isValid, isFalse, reason: '$email should be invalid');
      }
    });
  });

  group('Password Validation Tests', () {
    test('should validate password length', () {
      const validPassword = 'password123';
      const shortPassword = '12345';

      expect(validPassword.length >= 6, isTrue);
      expect(shortPassword.length >= 6, isFalse);
    });

    test('should check if passwords match', () {
      const password1 = 'password123';
      const password2 = 'password123';
      const password3 = 'different123';

      expect(password1 == password2, isTrue);
      expect(password1 == password3, isFalse);
    });

    test('should handle empty passwords', () {
      const emptyPassword = '';
      const validPassword = 'password123';

      expect(emptyPassword.isEmpty, isTrue);
      expect(validPassword.isEmpty, isFalse);
    });
  });

  group('User Data Tests', () {
    test('should extract email from user object', () {
      final mockUser = MockUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      expect(mockUser.email, 'test@example.com');
      expect(mockUser.uid, 'test-uid');
      expect(mockUser.displayName, 'Test User');
    });

    test('should handle null email', () {
      final mockUser = MockUser(
        uid: 'test-uid',
        email: null,
        displayName: 'Test User',
      );

      expect(mockUser.email, isNull);
      expect(mockUser.email ?? 'Unknown', 'Unknown');
    });

    test('should handle user with only email', () {
      final mockUser = MockUser(uid: 'test-uid', email: 'test@example.com');

      expect(mockUser.email, 'test@example.com');
      expect(mockUser.displayName, isNull);
    });
  });
}
