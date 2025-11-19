import 'package:padelhub/models/court.dart';

/// Representa la disponibilidad de una pista en un horario específico
class CourtAvailability {
  final Court court;
  final List<int> availableDurations; // [60, 90] minutos disponibles
  final String timeSlot; // HH:mm

  CourtAvailability({
    required this.court,
    required this.availableDurations,
    required this.timeSlot,
  });

  /// Calcula el precio para una duración específica
  double getPriceForDuration(int durationMinutes) {
    return (durationMinutes / 60) * court.pricePerHour;
  }

  /// Verifica si se puede reservar por 60 minutos
  bool canBook60Minutes() => availableDurations.contains(60);

  /// Verifica si se puede reservar por 90 minutos
  bool canBook90Minutes() => availableDurations.contains(90);

  /// Verifica si la pista está disponible
  bool get isAvailable => availableDurations.isNotEmpty;
}
