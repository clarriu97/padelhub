class Club {
  final String id;
  final String name;
  final String timezone;
  final String? address;
  final String? opensAt;
  final String? closesAt;
  final String? website;
  final String? phoneNumber;
  final bool hasAccessibleAccess;
  final bool hasParking;
  final bool hasShop;
  final bool hasCafeteria;
  final bool hasSnackBar;
  final bool hasChangingRooms;
  final bool hasLockers;

  Club({
    required this.id,
    required this.name,
    required this.timezone,
    this.address,
    this.opensAt,
    this.closesAt,
    this.website,
    this.phoneNumber,
    this.hasAccessibleAccess = false,
    this.hasParking = false,
    this.hasShop = false,
    this.hasCafeteria = false,
    this.hasSnackBar = false,
    this.hasChangingRooms = false,
    this.hasLockers = false,
  });

  factory Club.fromFirestore(String id, Map<String, dynamic> data) {
    return Club(
      id: id,
      name: data['name'] ?? '',
      timezone: data['timezone'] ?? 'Europe/Madrid',
      address: data['address'],
      opensAt: data['opens_at'],
      closesAt: data['closes_at'],
      website: data['website'],
      phoneNumber: data['phone_number'],
      hasAccessibleAccess: data['has_accessible_access'] ?? false,
      hasParking: data['has_parking'] ?? false,
      hasShop: data['has_shop'] ?? false,
      hasCafeteria: data['has_cafeteria'] ?? false,
      hasSnackBar: data['has_snack_bar'] ?? false,
      hasChangingRooms: data['has_changing_rooms'] ?? false,
      hasLockers: data['has_lockers'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'timezone': timezone,
      if (address != null) 'address': address,
      if (opensAt != null) 'opens_at': opensAt,
      if (closesAt != null) 'closes_at': closesAt,
      if (website != null) 'website': website,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      'has_accessible_access': hasAccessibleAccess,
      'has_parking': hasParking,
      'has_shop': hasShop,
      'has_cafeteria': hasCafeteria,
      'has_snack_bar': hasSnackBar,
      'has_changing_rooms': hasChangingRooms,
      'has_lockers': hasLockers,
    };
  }
}
