import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/models/booking.dart';

void main() {
  group('Booking Model Tests', () {
    test('should create Booking instance with all fields', () {
      final booking = Booking(
        id: 'booking123',
        clubId: 'club123',
        courtId: 'court123',
        userId: 'user123',
        date: '2025-11-20',
        startTime: '09:00',
        durationMinutes: 90,
        players: ['player1@example.com', 'player2@example.com'],
        price: 31.20,
        createdAt: DateTime(2025, 11, 18, 10, 0),
        status: 'active',
      );

      expect(booking.id, 'booking123');
      expect(booking.clubId, 'club123');
      expect(booking.courtId, 'court123');
      expect(booking.userId, 'user123');
      expect(booking.date, '2025-11-20');
      expect(booking.startTime, '09:00');
      expect(booking.durationMinutes, 90);
      expect(booking.players, hasLength(2));
      expect(booking.price, 31.20);
      expect(booking.status, 'active');
      expect(booking.invalidReason, isNull);
    });

    test('should serialize Booking to Firestore format', () {
      final booking = Booking(
        id: 'booking123',
        clubId: 'club123',
        courtId: 'court123',
        userId: 'user123',
        date: '2025-11-20',
        startTime: '09:00',
        durationMinutes: 60,
        players: ['player1@example.com'],
        price: 20.80,
        createdAt: DateTime(2025, 11, 18, 10, 0),
      );

      final firestoreData = booking.toFirestore();

      expect(firestoreData['clubId'], 'club123');
      expect(firestoreData['courtId'], 'court123');
      expect(firestoreData['userId'], 'user123');
      expect(firestoreData['date'], '2025-11-20');
      expect(firestoreData['startTime'], '09:00');
      expect(firestoreData['durationMinutes'], 60);
      expect(firestoreData['price'], 20.80);
      expect(firestoreData['status'], 'active');
    });

    test('should deserialize Booking from Firestore', () {
      final mockData = {
        'clubId': 'club123',
        'courtId': 'court123',
        'userId': 'user123',
        'date': '2025-11-20',
        'startTime': '14:30',
        'durationMinutes': 90,
        'players': ['player1@example.com', 'player2@example.com'],
        'price': 31.20,
        'createdAt': '2025-11-18T10:00:00.000',
        'status': 'active',
      };

      final booking = Booking.fromFirestore('booking123', mockData);

      expect(booking.id, 'booking123');
      expect(booking.clubId, 'club123');
      expect(booking.startTime, '14:30');
      expect(booking.durationMinutes, 90);
      expect(booking.status, 'active');
    });

    test('should calculate endTime correctly', () {
      final booking = Booking(
        id: 'booking123',
        clubId: 'club123',
        courtId: 'court123',
        userId: 'user123',
        date: '2025-11-20',
        startTime: '09:00',
        durationMinutes: 90,
        players: [],
        price: 31.20,
        createdAt: DateTime.now(),
      );

      expect(booking.endTime, '10:30');
    });

    test('should calculate endTime for 60 minutes', () {
      final booking = Booking(
        id: 'booking123',
        clubId: 'club123',
        courtId: 'court123',
        userId: 'user123',
        date: '2025-11-20',
        startTime: '14:30',
        durationMinutes: 60,
        players: [],
        price: 20.80,
        createdAt: DateTime.now(),
      );

      expect(booking.endTime, '15:30');
    });

    test('should handle invalid status', () {
      final booking = Booking(
        id: 'booking123',
        clubId: 'club123',
        courtId: 'court123',
        userId: 'user123',
        date: '2025-11-20',
        startTime: '09:00',
        durationMinutes: 60,
        players: [],
        price: 20.80,
        createdAt: DateTime.now(),
        status: 'invalid',
        invalidReason: 'Time slot no longer available',
      );

      expect(booking.status, 'invalid');
      expect(booking.invalidReason, 'Time slot no longer available');

      final firestoreData = booking.toFirestore();
      expect(firestoreData['invalidReason'], 'Time slot no longer available');
    });
  });
}
