class Court {
  final String id;
  final String name;
  final String surface;
  final bool indoor;
  final bool hasLighting;
  final bool hasAirConditioning;
  final String? description;

  Court({
    required this.id,
    required this.name,
    required this.surface,
    this.indoor = true,
    this.hasLighting = true,
    this.hasAirConditioning = true,
    this.description,
  });

  factory Court.fromFirestore(String id, Map<String, dynamic> data) {
    return Court(
      id: id,
      name: data['name'] ?? '',
      surface: data['surface'] ?? 'artificial grass',
      indoor: data['indoor'] ?? true,
      hasLighting: data['has_lighting'] ?? true,
      hasAirConditioning: data['has_air_conditioning'] ?? true,
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'surface': surface,
      'indoor': indoor,
      'has_lighting': hasLighting,
      'has_air_conditioning': hasAirConditioning,
      if (description != null) 'description': description,
    };
  }
}
