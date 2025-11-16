import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padelhub/models/club.dart';

class ClubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Crear un nuevo club
  Future<void> createClub({
    required String id,
    required String name,
    required String timezone,
    String? address,
    String? opensAt,
    String? closesAt,
  }) async {
    final club = Club(
      id: id,
      name: name,
      timezone: timezone,
      address: address,
      opensAt: opensAt,
      closesAt: closesAt,
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
