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

  // Sharing fields
  final bool sharingEnabled; // Si el propietario permite compartir
  final int maxPlayers; // Número máximo de jugadores (default: 4 para pádel)
  final List<String> sharedWith; // User IDs con permiso para usar la pista
  final List<Map<String, dynamic>> joinRequests; // Solicitudes pendientes

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
    this.sharingEnabled = false,
    this.maxPlayers = 4,
    this.sharedWith = const [],
    this.joinRequests = const [],
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
      sharingEnabled: data['sharingEnabled'] ?? false,
      maxPlayers: data['maxPlayers'] ?? 4,
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      joinRequests: List<Map<String, dynamic>>.from(
        (data['joinRequests'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
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
      'sharingEnabled': sharingEnabled,
      'maxPlayers': maxPlayers,
      'sharedWith': sharedWith,
      'joinRequests': joinRequests,
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

  // Sharing helpers
  bool get isUpcoming {
    return startDateTime.isAfter(DateTime.now());
  }

  bool get isPast {
    return endDateTime.isBefore(DateTime.now());
  }

  bool get hasAvailableSlots {
    final currentPlayers = sharedWith.length + 1; // +1 for owner
    return currentPlayers < maxPlayers;
  }

  bool canUserJoin(String userId) {
    // User can't join their own booking
    if (this.userId == userId) return false;

    // User can't join if already shared with them
    if (sharedWith.contains(userId)) return false;

    // User can't join if sharing is disabled
    if (!sharingEnabled) return false;

    // User can't join if no available slots
    if (!hasAvailableSlots) return false;

    // User can't join if booking is not active
    if (status != 'active') return false;

    // User can't join past bookings
    if (isPast) return false;

    return true;
  }

  bool hasJoinRequest(String userId) {
    return joinRequests.any((request) => request['userId'] == userId);
  }
}
