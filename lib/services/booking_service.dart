import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padelhub/models/booking.dart';
import 'package:padelhub/models/time_slot.dart';
import 'package:padelhub/models/court.dart';
import 'package:padelhub/models/court_availability.dart';

class BookingService {
  final FirebaseFirestore _firestore;

  BookingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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

  /// Obtener reservas futuras del usuario
  Future<List<Booking>> getUserUpcomingBookings(String userId) async {
    final allBookings = await getUserAccessibleBookings(userId);
    return allBookings.where((booking) => booking.isUpcoming).toList();
  }

  /// Obtener reservas pasadas del usuario
  Future<List<Booking>> getUserPastBookings(String userId) async {
    final allBookings = await getUserAccessibleBookings(userId);
    final pastBookings = allBookings
        .where((booking) => booking.isPast)
        .toList();
    // Ordenar descendente (más recientes primero)
    pastBookings.sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
    return pastBookings;
  }

  /// Obtener reservas del usuario en un rango de fechas
  Future<List<Booking>> getUserBookingsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final allBookings = await getUserBookings(userId);
    return allBookings.where((booking) {
      final bookingDate = booking.startDateTime;
      return bookingDate.isAfter(start) && bookingDate.isBefore(end);
    }).toList();
  }

  /// Obtener todas las reservas donde el usuario tiene acceso (propias + compartidas)
  Future<List<Booking>> getUserAccessibleBookings(String userId) async {
    final clubsSnapshot = await _firestore.collection('clubs').get();
    final List<Booking> allBookings = [];

    for (final clubDoc in clubsSnapshot.docs) {
      final courtsSnapshot = await clubDoc.reference.collection('courts').get();

      for (final courtDoc in courtsSnapshot.docs) {
        // Obtener reservas donde el usuario es el propietario
        final ownBookingsSnapshot = await courtDoc.reference
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'active')
            .get();

        allBookings.addAll(
          ownBookingsSnapshot.docs.map(
            (doc) => Booking.fromFirestore(doc.id, doc.data()),
          ),
        );

        // Obtener reservas compartidas con el usuario
        final sharedBookingsSnapshot = await courtDoc.reference
            .collection('bookings')
            .where('sharedWith', arrayContains: userId)
            .where('status', isEqualTo: 'active')
            .get();

        allBookings.addAll(
          sharedBookingsSnapshot.docs.map(
            (doc) => Booking.fromFirestore(doc.id, doc.data()),
          ),
        );
      }
    }

    // Eliminar duplicados y ordenar
    final uniqueBookings = <String, Booking>{};
    for (final booking in allBookings) {
      uniqueBookings[booking.id] = booking;
    }

    final result = uniqueBookings.values.toList();
    result.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return result;
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
    bool sharingEnabled = false,
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
      sharingEnabled: sharingEnabled,
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

  /// Solicitar unirse a una reserva
  Future<void> requestToJoinBooking({
    required String clubId,
    required String courtId,
    required String bookingId,
    required String userId,
    required String userName,
  }) async {
    final bookingRef = _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(courtId)
        .collection('bookings')
        .doc(bookingId);

    final bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found');
    }

    final booking = Booking.fromFirestore(bookingDoc.id, bookingDoc.data()!);

    // Verificar que el usuario puede unirse
    if (!booking.canUserJoin(userId)) {
      throw Exception('Cannot join this booking');
    }

    // Verificar que no haya una solicitud pendiente
    if (booking.hasJoinRequest(userId)) {
      throw Exception('Join request already exists');
    }

    // Añadir solicitud
    final joinRequest = {
      'userId': userId,
      'userName': userName,
      'requestedAt': DateTime.now().toIso8601String(),
    };

    await bookingRef.update({
      'joinRequests': FieldValue.arrayUnion([joinRequest]),
    });
  }

  /// Aprobar solicitud de unión
  Future<void> approveJoinRequest({
    required String clubId,
    required String courtId,
    required String bookingId,
    required String requestUserId,
  }) async {
    final bookingRef = _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(courtId)
        .collection('bookings')
        .doc(bookingId);

    final bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found');
    }

    final booking = Booking.fromFirestore(bookingDoc.id, bookingDoc.data()!);

    // Encontrar la solicitud
    final request = booking.joinRequests.firstWhere(
      (r) => r['userId'] == requestUserId,
      orElse: () => throw Exception('Join request not found'),
    );

    // Remover solicitud y añadir a sharedWith
    await bookingRef.update({
      'joinRequests': FieldValue.arrayRemove([request]),
      'sharedWith': FieldValue.arrayUnion([requestUserId]),
    });
  }

  /// Rechazar solicitud de unión
  Future<void> rejectJoinRequest({
    required String clubId,
    required String courtId,
    required String bookingId,
    required String requestUserId,
  }) async {
    final bookingRef = _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(courtId)
        .collection('bookings')
        .doc(bookingId);

    final bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found');
    }

    final booking = Booking.fromFirestore(bookingDoc.id, bookingDoc.data()!);

    // Encontrar la solicitud
    final request = booking.joinRequests.firstWhere(
      (r) => r['userId'] == requestUserId,
      orElse: () => throw Exception('Join request not found'),
    );

    // Remover solicitud
    await bookingRef.update({
      'joinRequests': FieldValue.arrayRemove([request]),
    });
  }

  /// Remover usuario compartido
  Future<void> removeSharedUser({
    required String clubId,
    required String courtId,
    required String bookingId,
    required String userId,
  }) async {
    await _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(courtId)
        .collection('bookings')
        .doc(bookingId)
        .update({
          'sharedWith': FieldValue.arrayRemove([userId]),
        });
  }

  /// Activar/desactivar compartir
  Future<void> toggleSharingEnabled({
    required String clubId,
    required String courtId,
    required String bookingId,
    required bool enabled,
  }) async {
    await _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(courtId)
        .collection('bookings')
        .doc(bookingId)
        .update({'sharingEnabled': enabled});
  }

  /// Obtener reservas compartibles en una fecha
  Future<List<Booking>> getShareableBookings({
    required String clubId,
    required List<Court> courts,
    required String date,
  }) async {
    final List<Booking> shareableBookings = [];

    for (final court in courts) {
      final bookingsSnapshot = await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('courts')
          .doc(court.id)
          .collection('bookings')
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: 'active')
          .where('sharingEnabled', isEqualTo: true)
          .get();

      final bookings = bookingsSnapshot.docs
          .map((doc) => Booking.fromFirestore(doc.id, doc.data()))
          .where((booking) => booking.hasAvailableSlots && booking.isUpcoming)
          .toList();

      shareableBookings.addAll(bookings);
    }

    // Ordenar por hora de inicio
    shareableBookings.sort((a, b) => a.startTime.compareTo(b.startTime));
    return shareableBookings;
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
