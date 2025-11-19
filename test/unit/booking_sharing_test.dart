import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/models/booking.dart';

void main() {
  group('Booking Model - Sharing Features', () {
    late Booking testBooking;
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: 1));
    final pastDate = now.subtract(const Duration(days: 1));

    setUp(() {
      testBooking = Booking(
        id: 'test-booking-1',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: '2025-11-20',
        startTime: '10:00',
        durationMinutes: 90,
        players: ['player1@example.com'],
        price: 30.0,
        createdAt: now,
        sharingEnabled: true,
        maxPlayers: 4,
        sharedWith: ['user-2'],
        joinRequests: [
          {
            'userId': 'user-3',
            'userName': 'User 3',
            'requestedAt': now.toIso8601String(),
          },
        ],
      );
    });

    test('should serialize and deserialize with sharing fields', () {
      final firestore = testBooking.toFirestore();

      expect(firestore['sharingEnabled'], true);
      expect(firestore['maxPlayers'], 4);
      expect(firestore['sharedWith'], ['user-2']);
      expect(firestore['joinRequests'], hasLength(1));

      final deserialized = Booking.fromFirestore('test-booking-1', firestore);

      expect(deserialized.sharingEnabled, true);
      expect(deserialized.maxPlayers, 4);
      expect(deserialized.sharedWith, ['user-2']);
      expect(deserialized.joinRequests, hasLength(1));
      expect(deserialized.joinRequests[0]['userId'], 'user-3');
    });

    test('should have default values for sharing fields', () {
      final booking = Booking(
        id: 'test',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: '2025-11-20',
        startTime: '10:00',
        durationMinutes: 60,
        players: ['player@example.com'],
        price: 20.0,
        createdAt: now,
      );

      expect(booking.sharingEnabled, false);
      expect(booking.maxPlayers, 4);
      expect(booking.sharedWith, isEmpty);
      expect(booking.joinRequests, isEmpty);
    });

    test('isUpcoming should return true for future bookings', () {
      final upcomingBooking = Booking(
        id: 'test',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: futureDate.toIso8601String().split('T')[0],
        startTime: '14:00',
        durationMinutes: 60,
        players: ['player@example.com'],
        price: 20.0,
        createdAt: now,
      );

      expect(upcomingBooking.isUpcoming, true);
    });

    test('isPast should return true for past bookings', () {
      final pastBooking = Booking(
        id: 'test',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: pastDate.toIso8601String().split('T')[0],
        startTime: '10:00',
        durationMinutes: 60,
        players: ['player@example.com'],
        price: 20.0,
        createdAt: now,
      );

      expect(pastBooking.isPast, true);
    });

    test('hasAvailableSlots should check player count correctly', () {
      final fullBooking = Booking(
        id: 'test',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: '2025-11-20',
        startTime: '10:00',
        durationMinutes: 60,
        players: ['player@example.com'],
        price: 20.0,
        createdAt: now,
        maxPlayers: 4,
        sharedWith: ['user-2', 'user-3', 'user-4'], // 3 shared + 1 owner = 4
      );

      expect(fullBooking.hasAvailableSlots, false);

      final partialBooking = Booking(
        id: 'test',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: '2025-11-20',
        startTime: '10:00',
        durationMinutes: 60,
        players: ['player@example.com'],
        price: 20.0,
        createdAt: now,
        maxPlayers: 4,
        sharedWith: ['user-2'], // 1 shared + 1 owner = 2 < 4
      );

      expect(partialBooking.hasAvailableSlots, true);
    });

    test('canUserJoin should validate all conditions', () {
      final futureBooking = Booking(
        id: 'test',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: futureDate.toIso8601String().split('T')[0],
        startTime: '14:00',
        durationMinutes: 60,
        players: ['player@example.com'],
        price: 20.0,
        createdAt: now,
        sharingEnabled: true,
        maxPlayers: 4,
        sharedWith: ['user-2'],
      );

      // User can join
      expect(futureBooking.canUserJoin('user-3'), true);

      // Owner cannot join their own booking
      expect(futureBooking.canUserJoin('user-1'), false);

      // Already shared user cannot join again
      expect(futureBooking.canUserJoin('user-2'), false);

      // Cannot join if sharing disabled
      final privateBooking = Booking(
        id: 'test',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: futureDate.toIso8601String().split('T')[0],
        startTime: '14:00',
        durationMinutes: 60,
        players: ['player@example.com'],
        price: 20.0,
        createdAt: now,
        sharingEnabled: false,
      );

      expect(privateBooking.canUserJoin('user-3'), false);

      // Cannot join if no available slots
      final fullBooking = Booking(
        id: 'test',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: futureDate.toIso8601String().split('T')[0],
        startTime: '14:00',
        durationMinutes: 60,
        players: ['player@example.com'],
        price: 20.0,
        createdAt: now,
        sharingEnabled: true,
        maxPlayers: 4,
        sharedWith: ['user-2', 'user-3', 'user-4'],
      );

      expect(fullBooking.canUserJoin('user-5'), false);

      // Cannot join cancelled booking
      final cancelledBooking = Booking(
        id: 'test',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: futureDate.toIso8601String().split('T')[0],
        startTime: '14:00',
        durationMinutes: 60,
        players: ['player@example.com'],
        price: 20.0,
        createdAt: now,
        status: 'cancelled',
        sharingEnabled: true,
      );

      expect(cancelledBooking.canUserJoin('user-3'), false);

      // Cannot join past booking
      final pastBooking = Booking(
        id: 'test',
        clubId: 'club-1',
        courtId: 'court-1',
        userId: 'user-1',
        date: pastDate.toIso8601String().split('T')[0],
        startTime: '10:00',
        durationMinutes: 60,
        players: ['player@example.com'],
        price: 20.0,
        createdAt: now,
        sharingEnabled: true,
      );

      expect(pastBooking.canUserJoin('user-3'), false);
    });

    test('hasJoinRequest should check if user has pending request', () {
      expect(testBooking.hasJoinRequest('user-3'), true);
      expect(testBooking.hasJoinRequest('user-4'), false);
    });
  });
}
