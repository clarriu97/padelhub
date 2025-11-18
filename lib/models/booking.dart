class Booking {
  final String id;
  final String clubId;
  final String courtId;
  final String userId;
  final String date; // formato: YYYY-MM-DD
  final String startTime; // formato: HH:mm
  final int durationMinutes; // 60 o 90
  final List<String> players; // emails o nombres de jugadores
  final double price;
  final DateTime createdAt;
  final String status; // 'active', 'cancelled', 'invalid'
  final String? invalidReason;

  Booking({
    required this.id,
    required this.clubId,
    required this.courtId,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.players,
    required this.price,
    required this.createdAt,
    this.status = 'active',
    this.invalidReason,
  });

  factory Booking.fromFirestore(String id, Map<String, dynamic> data) {
    return Booking(
      id: id,
      clubId: data['clubId'] ?? '',
      courtId: data['courtId'] ?? '',
      userId: data['userId'] ?? '',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 60,
      players: List<String>.from(data['players'] ?? []),
      price: (data['price'] ?? 0).toDouble(),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      status: data['status'] ?? 'active',
      invalidReason: data['invalidReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clubId': clubId,
      'courtId': courtId,
      'userId': userId,
      'date': date,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'players': players,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      if (invalidReason != null) 'invalidReason': invalidReason,
    };
  }

  // Helpers
  DateTime get startDateTime {
    final parts = startTime.split(':');
    final dateParts = date.split('-');
    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  DateTime get endDateTime {
    return startDateTime.add(Duration(minutes: durationMinutes));
  }

  String get endTime {
    final end = endDateTime;
    return '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }
}
