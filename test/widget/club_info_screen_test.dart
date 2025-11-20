import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/screens/home/club_info_screen.dart';

void main() {
  late Club testClub;

  setUp(() {
    testClub = Club(
      id: 'test-club',
      name: 'Test Padel Club',
      timezone: 'Europe/Madrid',
      address: 'Calle Test 123, Madrid',
      opensAt: '08:00',
      closesAt: '23:00',
      website: 'https://testclub.com',
      phoneNumber: '+34 123 456 789',
      hasAccessibleAccess: true,
      hasParking: true,
      hasShop: true,
      hasCafeteria: true,
      hasSnackBar: false,
      hasChangingRooms: true,
      hasLockers: true,
    );
  });

  Widget createTestWidget(Club club) {
    return MaterialApp(
      home: Scaffold(body: ClubInfoScreen(club: club)),
    );
  }

  group('ClubInfoScreen Widget Tests', () {
    testWidgets('displays contact information section', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('Contact Information'), findsOneWidget);
    });

    testWidgets('displays phone number when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('+34 123 456 789'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });

    testWidgets('displays website when available', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('https://testclub.com'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('displays opening hours when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('08:00 - 23:00'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('displays amenities section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('Amenities'), findsOneWidget);
    });

    testWidgets('displays parking amenity when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('Parking'), findsOneWidget);
      expect(find.byIcon(Icons.local_parking), findsOneWidget);
    });

    testWidgets('displays shop amenity when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('Shop'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
    });

    testWidgets('displays cafeteria amenity when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('Cafeteria'), findsOneWidget);
      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets('displays changing rooms amenity when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('Changing Rooms'), findsOneWidget);
      expect(find.byIcon(Icons.checkroom), findsOneWidget);
    });

    testWidgets('displays lockers amenity when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('Lockers'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('does not display snack bar amenity when not available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('Snack Bar'), findsNothing);
    });

    testWidgets('displays accessible amenity when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.text('Accessible'), findsOneWidget);
      expect(find.byIcon(Icons.accessible), findsOneWidget);
    });

    testWidgets('does not display phone when not available', (
      WidgetTester tester,
    ) async {
      final clubWithoutPhone = Club(
        id: 'test-club',
        name: 'Test Club',
        timezone: 'Europe/Madrid',
      );

      await tester.pumpWidget(createTestWidget(clubWithoutPhone));

      expect(find.byIcon(Icons.phone), findsNothing);
    });

    testWidgets('does not display website when not available', (
      WidgetTester tester,
    ) async {
      final clubWithoutWebsite = Club(
        id: 'test-club',
        name: 'Test Club',
        timezone: 'Europe/Madrid',
      );

      await tester.pumpWidget(createTestWidget(clubWithoutWebsite));

      expect(find.byIcon(Icons.language), findsNothing);
    });

    testWidgets('screen is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testClub));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
