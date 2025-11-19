import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:padelhub/screens/booking/booking_screen.dart';
import 'package:padelhub/models/club.dart';
import 'package:padelhub/models/court.dart';
import 'package:padelhub/services/club_service.dart';
import 'package:padelhub/services/court_service.dart';
import 'package:padelhub/services/booking_service.dart';

// Mocks
class MockClubService extends Mock implements ClubService {
  @override
  Stream<List<Club>> getClubs() {
    return super.noSuchMethod(
      Invocation.method(#getClubs, []),
      returnValue: Stream.value(<Club>[]),
      returnValueForMissingStub: Stream.value(<Club>[]),
    );
  }
}

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
  late MockClubService mockClubService;
  late MockCourtService mockCourtService;
  late MockBookingService mockBookingService;

  setUp(() {
    mockClubService = MockClubService();
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
    when(mockClubService.getClubs()).thenAnswer((_) => Stream.value([club]));
    when(mockCourtService.getCourts(any)).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(
      MaterialApp(
        home: BookingScreen(
          clubService: mockClubService,
          courtService: mockCourtService,
          bookingService: mockBookingService,
        ),
      ),
    );

    await tester.pumpAndSettle(); // Wait for stream to emit

    expect(
      find.text('Test Club'),
      findsWidgets,
    ); // Should be in dropdown and title
    expect(find.text('Select Club'), findsOneWidget);
  });
}
