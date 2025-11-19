import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/models/booking.dart';

void main() {
  group('BookingService - User Bookings Logic', () {
    test('should filter upcoming bookings correctly', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 1));
      final pastDate = now.subtract(const Duration(days: 1));

      final bookings = [
        Booking(
          id: 'booking-1',
          clubId: 'club-1',
          courtId: 'court-1',
          userId: 'user-1',
          date: futureDate.toIso8601String().split('T')[0],
          startTime: '14:00',
          durationMinutes: 60,
          players: ['player@example.com'],
          price: 20.0,
          createdAt: now,
        ),
        Booking(
          id: 'booking-2',
          clubId: 'club-1',
          courtId: 'court-1',
          userId: 'user-1',
          date: pastDate.toIso8601String().split('T')[0],
          startTime: '10:00',
          durationMinutes: 60,
          players: ['player@example.com'],
          price: 20.0,
          createdAt: now,
        ),
      ];

      final upcoming = bookings.where((b) => b.isUpcoming).toList();
      final past = bookings.where((b) => b.isPast).toList();

      expect(upcoming, hasLength(1));
      expect(upcoming[0].id, 'booking-1');
      expect(past, hasLength(1));
      expect(past[0].id, 'booking-2');
    });

    test('should sort past bookings in descending order', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      final bookings = [
        Booking(
          id: 'booking-1',
          clubId: 'club-1',
          courtId: 'court-1',
          userId: 'user-1',
          date: twoDaysAgo.toIso8601String().split('T')[0],
          startTime: '10:00',
          durationMinutes: 60,
          players: ['player@example.com'],
          price: 20.0,
          createdAt: now,
        ),
        Booking(
          id: 'booking-2',
          clubId: 'club-1',
          courtId: 'court-1',
          userId: 'user-1',
          date: yesterday.toIso8601String().split('T')[0],
          startTime: '10:00',
          durationMinutes: 60,
          players: ['player@example.com'],
          price: 20.0,
          createdAt: now,
        ),
      ];

      final sorted = bookings.toList()
        ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));

      expect(sorted[0].id, 'booking-2'); // More recent first
      expect(sorted[1].id, 'booking-1');
    });

    test('should filter bookings by date range', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 1));
      final end = now.add(const Duration(days: 2));
      final outsideRange = now.add(const Duration(days: 5));

      final bookings = [
        Booking(
          id: 'booking-1',
          clubId: 'club-1',
          courtId: 'court-1',
          userId: 'user-1',
          date: now.toIso8601String().split('T')[0],
          startTime: '14:00',
          durationMinutes: 60,
          players: ['player@example.com'],
          price: 20.0,
          createdAt: now,
        ),
        Booking(
          id: 'booking-2',
          clubId: 'club-1',
          courtId: 'court-1',
          userId: 'user-1',
          date: outsideRange.toIso8601String().split('T')[0],
          startTime: '10:00',
          durationMinutes: 60,
          players: ['player@example.com'],
          price: 20.0,
          createdAt: now,
        ),
      ];

      final filtered = bookings.where((booking) {
        final bookingDate = booking.startDateTime;
        return bookingDate.isAfter(start) && bookingDate.isBefore(end);
      }).toList();

      expect(filtered, hasLength(1));
      expect(filtered[0].id, 'booking-1');
    });
  });

  group('BookingService - Join Request Logic', () {
    test('should validate join request conditions', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 1));

      final booking = Booking(
        id: 'booking-1',
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
        sharedWith: [],
        joinRequests: [],
      );

      // Can request to join
      expect(booking.canUserJoin('user-2'), true);
      expect(booking.hasJoinRequest('user-2'), false);
    });

    test('should prevent duplicate join requests', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 1));

      final booking = Booking(
        id: 'booking-1',
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
        joinRequests: [
          {
            'userId': 'user-2',
            'userName': 'User 2',
            'requestedAt': now.toIso8601String(),
          },
        ],
      );

      expect(booking.hasJoinRequest('user-2'), true);
      expect(booking.hasJoinRequest('user-3'), false);
    });

    test('should respect max players limit', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 1));

      final booking = Booking(
        id: 'booking-1',
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
        sharedWith: ['user-2', 'user-3', 'user-4'], // Full
      );

      expect(booking.hasAvailableSlots, false);
      expect(booking.canUserJoin('user-5'), false);
    });
  });

  group('BookingService - Shareable Bookings', () {
    test('should filter shareable bookings correctly', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 1));

      final bookings = [
        Booking(
          id: 'booking-1',
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
          sharedWith: [],
        ),
        Booking(
          id: 'booking-2',
          clubId: 'club-1',
          courtId: 'court-1',
          userId: 'user-2',
          date: futureDate.toIso8601String().split('T')[0],
          startTime: '15:00',
          durationMinutes: 60,
          players: ['player@example.com'],
          price: 20.0,
          createdAt: now,
          sharingEnabled: false, // Not shareable
        ),
        Booking(
          id: 'booking-3',
          clubId: 'club-1',
          courtId: 'court-1',
          userId: 'user-3',
          date: futureDate.toIso8601String().split('T')[0],
          startTime: '16:00',
          durationMinutes: 60,
          players: ['player@example.com'],
          price: 20.0,
          createdAt: now,
          sharingEnabled: true,
          maxPlayers: 4,
          sharedWith: ['user-4', 'user-5', 'user-6'], // Full
        ),
      ];

      final shareable = bookings
          .where((b) => b.sharingEnabled && b.hasAvailableSlots && b.isUpcoming)
          .toList();

      expect(shareable, hasLength(1));
      expect(shareable[0].id, 'booking-1');
    });
  });
}
