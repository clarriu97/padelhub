import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/screens/home/open_matches_screen.dart';
import 'package:padelhub/services/booking_service.dart';
import 'package:padelhub/services/court_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late Club testClub;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    testClub = Club(
      id: 'test-club',
      name: 'Test Club',
      timezone: 'Europe/Madrid',
      opensAt: '08:00',
      closesAt: '23:00',
    );
  });

  Widget createTestWidget({
    CourtService? courtService,
    BookingService? bookingService,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: OpenMatchesScreen(
          club: testClub,
          courtService: courtService,
          bookingService: bookingService,
        ),
      ),
    );
  }

  group('OpenMatchesScreen Widget Tests', () {
    testWidgets('displays date selector', (WidgetTester tester) async {
      final courtService = CourtService(firestore: fakeFirestore);
      final bookingService = BookingService(firestore: fakeFirestore);

      await tester.pumpWidget(
        createTestWidget(
          courtService: courtService,
          bookingService: bookingService,
        ),
      );

      await tester.pump();

      // Should have horizontal scrollable date selector
      expect(find.byType(ListView), findsAtLeastNWidgets(1));
    });

    testWidgets('shows no matches message when no shareable bookings exist', (
      WidgetTester tester,
    ) async {
      final courtService = CourtService(firestore: fakeFirestore);
      final bookingService = BookingService(firestore: fakeFirestore);

      await tester.pumpWidget(
        createTestWidget(
          courtService: courtService,
          bookingService: bookingService,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No open matches for this date'), findsOneWidget);
    });

    testWidgets('has column layout', (WidgetTester tester) async {
      final courtService = CourtService(firestore: fakeFirestore);
      final bookingService = BookingService(firestore: fakeFirestore);

      await tester.pumpWidget(
        createTestWidget(
          courtService: courtService,
          bookingService: bookingService,
        ),
      );

      await tester.pump();

      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });
  });
}
