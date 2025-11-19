import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padelhub/models/booking.dart';
import 'package:padelhub/models/time_slot.dart';
import 'package:padelhub/models/court.dart';
import 'package:padelhub/models/court_availability.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener todas las reservas activas de una pista en una fecha específica
  Stream<List<Booking>> getCourtBookings({
    required String clubId,
    required String courtId,
    required String date,
  }) {
    return _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(courtId)
        .collection('bookings')
        .where('date', isEqualTo: date)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Booking.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Obtener todas las reservas de un club en una fecha específica (todas las pistas)
  Future<Map<String, List<Booking>>> getClubBookingsForDate({
    required String clubId,
    required List<Court> courts,
    required String date,
  }) async {
    final Map<String, List<Booking>> bookingsByCourtId = {};

    for (final court in courts) {
      final bookingsSnapshot = await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('courts')
          .doc(court.id)
          .collection('bookings')
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: 'active')
          .get();

      bookingsByCourtId[court.id] = bookingsSnapshot.docs
          .map((doc) => Booking.fromFirestore(doc.id, doc.data()))
          .toList();
    }

    return bookingsByCourtId;
  }

  /// Calcular slots de tiempo disponibles considerando todas las pistas
  List<TimeSlot> calculateAvailableTimeSlots({
    required Map<String, List<Booking>> bookingsByCourtId,
    required List<Court> courts,
    required String opensAt,
    required String closesAt,
  }) {
    final slots = <TimeSlot>[];
    final openMinutes = _timeToMinutes(opensAt);
    final closeMinutes = _timeToMinutes(closesAt);

    // Generar slots cada 30 minutos
    for (int minutes = openMinutes; minutes < closeMinutes; minutes += 30) {
      final timeStr = _minutesToTime(minutes);
      
      // Verificar si al menos una pista está disponible en este horario
      bool hasAvailability = false;
      
      for (final court in courts) {
        final courtBookings = bookingsByCourtId[court.id] ?? [];
        final availableDurations = _getAvailableDurations(
          minutes,
          closeMinutes,
          courtBookings,
        );
        
        if (availableDurations.isNotEmpty) {
          hasAvailability = true;
          break;
        }
      }

      if (hasAvailability) {
        slots.add(
          TimeSlot(
            startTime: timeStr,
            availableDurations: [60, 90], // Placeholder, se calculará por pista
            isAvailable: true,
          ),
        );
      }
    }

    return slots;
  }

  /// Obtener pistas disponibles para un slot de tiempo específico
  List<CourtAvailability> getAvailableCourtsForTimeSlot({
    required String timeSlot,
    required Map<String, List<Booking>> bookingsByCourtId,
    required List<Court> courts,
    required String closesAt,
  }) {
    final availableCourts = <CourtAvailability>[];
    final slotMinutes = _timeToMinutes(timeSlot);
    final closeMinutes = _timeToMinutes(closesAt);

    for (final court in courts) {
      final courtBookings = bookingsByCourtId[court.id] ?? [];
      final availableDurations = _getAvailableDurations(
        slotMinutes,
        closeMinutes,
        courtBookings,
      );

      if (availableDurations.isNotEmpty) {
        availableCourts.add(
          CourtAvailability(
            court: court,
            availableDurations: availableDurations,
            timeSlot: timeSlot,
          ),
        );
      }
    }

    return availableCourts;
  }

  /// Obtener las reservas de un usuario
  Future<List<Booking>> getUserBookings(String userId) async {
    // Nota: Esta query requiere un índice compuesto en Firestore
    // Firestore te lo pedirá automáticamente cuando lo uses
    final clubsSnapshot = await _firestore.collection('clubs').get();

    final List<Booking> allBookings = [];

    for (final clubDoc in clubsSnapshot.docs) {
      final courtsSnapshot = await clubDoc.reference.collection('courts').get();

      for (final courtDoc in courtsSnapshot.docs) {
        final bookingsSnapshot = await courtDoc.reference
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'active')
            .get();

        allBookings.addAll(
          bookingsSnapshot.docs.map(
            (doc) => Booking.fromFirestore(doc.id, doc.data()),
          ),
        );
      }
    }

    // Ordenar por fecha y hora
    allBookings.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return allBookings;
  }

  /// Calcular slots disponibles para una pista en una fecha
  List<TimeSlot> calculateAvailableSlots({
    required List<Booking> existingBookings,
    required String opensAt, // "08:00"
    required String closesAt, // "23:00"
  }) {
    final slots = <TimeSlot>[];

    // Convertir horarios a minutos
    final openMinutes = _timeToMinutes(opensAt);
    final closeMinutes = _timeToMinutes(closesAt);

    // Generar slots cada 30 minutos
    for (int minutes = openMinutes; minutes < closeMinutes; minutes += 30) {
      final timeStr = _minutesToTime(minutes);
      final availableDurations = _getAvailableDurations(
        minutes,
        closeMinutes,
        existingBookings,
      );

      if (availableDurations.isNotEmpty) {
        slots.add(
          TimeSlot(
            startTime: timeStr,
            availableDurations: availableDurations,
            isAvailable: true,
          ),
        );
      }
    }

    return slots;
  }

  /// Determinar qué duraciones están disponibles para un slot
  List<int> _getAvailableDurations(
    int startMinutes,
    int closeMinutes,
    List<Booking> existingBookings,
  ) {
    final durations = <int>[];

    // Verificar si puede reservar 60 minutos
    if (_canBook(startMinutes, 60, closeMinutes, existingBookings)) {
      durations.add(60);
    }

    // Verificar si puede reservar 90 minutos
    if (_canBook(startMinutes, 90, closeMinutes, existingBookings)) {
      durations.add(90);
    }

    return durations;
  }

  /// Verificar si se puede hacer una reserva sin solapamientos
  bool _canBook(
    int startMinutes,
    int duration,
    int closeMinutes,
    List<Booking> existingBookings,
  ) {
    final endMinutes = startMinutes + duration;

    // Verificar que no cierre el club
    if (endMinutes > closeMinutes) return false;

    // Verificar solapamientos con reservas existentes
    for (final booking in existingBookings) {
      final bookingStart = _timeToMinutes(booking.startTime);
      final bookingEnd = bookingStart + booking.durationMinutes;

      // Hay solapamiento si: start < bookingEnd && bookingStart < end
      if (startMinutes < bookingEnd && bookingStart < endMinutes) {
        return false;
      }
    }

    return true;
  }

  /// Crear una nueva reserva
  Future<String> createBooking({
    required String clubId,
    required String courtId,
    required String userId,
    required String date,
    required String startTime,
    required int durationMinutes,
    required List<String> players,
    required double price,
  }) async {
    final booking = Booking(
      id: '', // Firestore generará el ID
      clubId: clubId,
      courtId: courtId,
      userId: userId,
      date: date,
      startTime: startTime,
      durationMinutes: durationMinutes,
      players: players,
      price: price,
      createdAt: DateTime.now(),
      status: 'active',
    );

    final docRef = await _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(courtId)
        .collection('bookings')
        .add(booking.toFirestore());

    return docRef.id;
  }

  /// Cancelar una reserva
  Future<void> cancelBooking({
    required String clubId,
    required String courtId,
    required String bookingId,
  }) async {
    await _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(courtId)
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'cancelled'});
  }

  // Helpers para conversión de tiempo
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _minutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Calcular precio basado en duración
  double calculatePrice({
    required int durationMinutes,
    required double pricePerHour,
  }) {
    return (durationMinutes / 60) * pricePerHour;
  }
}
