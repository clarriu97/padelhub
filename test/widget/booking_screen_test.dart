import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:padelhub/screens/booking/booking_screen.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/models/court.dart';
import 'package:padelhub/services/court_service.dart';
import 'package:padelhub/services/booking_service.dart';

// Mocks
class MockCourtService extends Mock implements CourtService {
  @override
  Stream<List<Court>> getCourts(String? clubId) {
    return super.noSuchMethod(
      Invocation.method(#getCourts, [clubId]),
      returnValue: Stream.value(<Court>[]),
      returnValueForMissingStub: Stream.value(<Court>[]),
    );
  }
}

class MockBookingService extends Mock implements BookingService {}

void main() {
  late MockCourtService mockCourtService;
  late MockBookingService mockBookingService;

  setUp(() {
    mockCourtService = MockCourtService();
    mockBookingService = MockBookingService();
  });

  testWidgets('BookingScreen renders correctly', (WidgetTester tester) async {
    // Setup mock data
    final club = Club(
      id: 'club1',
      name: 'Test Club',
      timezone: 'Europe/Madrid',
      address: '123 Test St',
      opensAt: '09:00',
      closesAt: '22:00',
      hasParking: true,
      hasCafeteria: true,
    );

    // Stub service calls
    when(mockCourtService.getCourts(any)).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookingScreen(
            club: club,
            courtService: mockCourtService,
            bookingService: mockBookingService,
          ),
        ),
      ),
    );

    await tester.pump(); // Initial frame

    // Should have date selector
    expect(find.byType(ListView), findsAtLeastNWidgets(1));
  });
}
