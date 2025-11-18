class TimeSlot {
  final String startTime; // HH:mm
  final List<int> availableDurations; // [60] o [60, 90]
  final bool isAvailable;

  TimeSlot({
    required this.startTime,
    required this.availableDurations,
    this.isAvailable = true,
  });

  String get displayTime => startTime;

  bool canBook60Minutes() => availableDurations.contains(60);
  bool canBook90Minutes() => availableDurations.contains(90);
}
