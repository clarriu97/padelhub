class Club {
  final String id;
  final String name;
  final String timezone;
  final String? address;
  final String? opensAt;
  final String? closesAt;

  Club({
    required this.id,
    required this.name,
    required this.timezone,
    this.address,
    this.opensAt,
    this.closesAt,
  });

  factory Club.fromFirestore(String id, Map<String, dynamic> data) {
    return Club(
      id: id,
      name: data['name'] ?? '',
      timezone: data['timezone'] ?? 'Europe/Madrid',
      address: data['address'],
      opensAt: data['opens_at'],
      closesAt: data['closes_at'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'timezone': timezone,
      if (address != null) 'address': address,
      if (opensAt != null) 'opens_at': opensAt,
      if (closesAt != null) 'closes_at': closesAt,
    };
  }
}
