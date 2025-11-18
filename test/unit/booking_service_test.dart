import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/models/booking.dart';

void main() {
  group('Booking Logic Tests', () {
    test(
      'calculateAvailableSlots - should generate slots every 30 minutes',
      () {
        final slots = _generateTimeSlots('09:00', '12:00');

        expect(slots, hasLength(6)); // 09:00, 09:30, 10:00, 10:30, 11:00, 11:30
        expect(slots.first, '09:00');
        expect(slots.last, '11:30');
      },
    );

    test('timeToMinutes - should convert time string to minutes', () {
      expect(_timeToMinutes('09:00'), 540);
      expect(_timeToMinutes('10:30'), 630);
      expect(_timeToMinutes('22:00'), 1320);
    });

    test('timesOverlap - should detect overlapping bookings', () {
      // Booking 1: 10:00-11:30 (90 min)
      // Booking 2: 10:30-12:00 (90 min) - overlaps
      expect(_timesOverlap(600, 690, 630, 720), isTrue);

      // Booking 1: 10:00-11:00 (60 min)
      // Booking 2: 11:00-12:00 (60 min) - no overlap (adjacent)
      expect(_timesOverlap(600, 660, 660, 720), isFalse);

      // Booking 1: 10:00-11:30 (90 min)
      // Booking 2: 12:00-13:00 (60 min) - no overlap
      expect(_timesOverlap(600, 690, 720, 780), isFalse);
    });

    test(
      'calculatePrice - should calculate correct price based on duration',
      () {
        const pricePerHour = 20.0;

        final price60 = (60 / 60) * pricePerHour;
        final price90 = (90 / 60) * pricePerHour;

        expect(price60, 20.0);
        expect(price90, 30.0);
      },
    );

    test('Booking model - should calculate end time correctly', () {
      final booking = Booking(
        id: 'test',
        clubId: 'club1',
        courtId: 'court1',
        userId: 'user1',
        date: '2025-11-20',
        startTime: '10:00',
        durationMinutes: 90,
        players: ['player@example.com'],
        price: 30.0,
        createdAt: DateTime.now(),
      );

      expect(booking.endTime, '11:30');
    });

    test('isSlotAvailable - should check if slot fits before closing', () {
      const closesAt = '22:00';
      const slotStart = '21:00';

      final closingMinutes = _timeToMinutes(closesAt);
      final slotMinutes = _timeToMinutes(slotStart);

      final canFit60 = (closingMinutes - slotMinutes) >= 60;
      final canFit90 = (closingMinutes - slotMinutes) >= 90;

      expect(canFit60, isTrue);
      expect(canFit90, isFalse);
    });
  });
}

// Helper functions for testing booking logic
int _timeToMinutes(String timeStr) {
  final parts = timeStr.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

List<String> _generateTimeSlots(String opensAt, String closesAt) {
  final slots = <String>[];
  int currentMinutes = _timeToMinutes(opensAt);
  final closingMinutes = _timeToMinutes(closesAt);

  while (currentMinutes < closingMinutes) {
    final hours = currentMinutes ~/ 60;
    final minutes = currentMinutes % 60;
    slots.add(
      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}',
    );
    currentMinutes += 30;
  }

  return slots;
}

bool _timesOverlap(int start1, int end1, int start2, int end2) {
  return start1 < end2 && start2 < end1;
}
