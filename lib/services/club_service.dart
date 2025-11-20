import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padelhub/models/club.dart';

class ClubService {
  final FirebaseFirestore _firestore;

  ClubService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Obtener todos los clubs
  Stream<List<Club>> getClubs() {
    return _firestore
        .collection('clubs')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Club.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  // Obtener el club por defecto (el primero que encuentre)
  Future<Club?> getDefaultClub() async {
    final snapshot = await _firestore.collection('clubs').limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return Club.fromFirestore(
      snapshot.docs.first.id,
      snapshot.docs.first.data(),
    );
  }

  // Crear un nuevo club
  Future<void> createClub({
    required String id,
    required String name,
    required String timezone,
    String? address,
    String? opensAt,
    String? closesAt,
    String? website,
    String? phoneNumber,
    bool hasAccessibleAccess = false,
    bool hasParking = false,
    bool hasShop = false,
    bool hasCafeteria = false,
    bool hasSnackBar = false,
    bool hasChangingRooms = false,
    bool hasLockers = false,
  }) async {
    final club = Club(
      id: id,
      name: name,
      timezone: timezone,
      address: address,
      opensAt: opensAt,
      closesAt: closesAt,
      website: website,
      phoneNumber: phoneNumber,
      hasAccessibleAccess: hasAccessibleAccess,
      hasParking: hasParking,
      hasShop: hasShop,
      hasCafeteria: hasCafeteria,
      hasSnackBar: hasSnackBar,
      hasChangingRooms: hasChangingRooms,
      hasLockers: hasLockers,
    );

    await _firestore.collection('clubs').doc(id).set(club.toFirestore());
  }

  // Actualizar un club
  Future<void> updateClub(Club club) async {
    await _firestore
        .collection('clubs')
        .doc(club.id)
        .update(club.toFirestore());
  }

  // Eliminar un club
  Future<void> deleteClub(String clubId) async {
    // Primero eliminar todas las courts del club
    final courtsSnapshot = await _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .get();

    for (var doc in courtsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Luego eliminar el club
    await _firestore.collection('clubs').doc(clubId).delete();
  }

  // Verificar si el usuario es admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }
}
