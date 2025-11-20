import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padelhub/models/court.dart';

class CourtService {
  final FirebaseFirestore _firestore;

  CourtService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Obtener todas las pistas de un club
  Stream<List<Court>> getCourts(String clubId) {
    return _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Court.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  // Crear una nueva pista
  Future<void> createCourt({
    required String clubId,
    required String id,
    required String name,
    required String surface,
    bool indoor = true,
    bool hasLighting = true,
    bool hasAirConditioning = true,
    String? description,
  }) async {
    final court = Court(
      id: id,
      name: name,
      surface: surface,
      indoor: indoor,
      hasLighting: hasLighting,
      hasAirConditioning: hasAirConditioning,
      description: description,
    );

    await _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(id)
        .set(court.toFirestore());
  }

  // Actualizar una pista
  Future<void> updateCourt(String clubId, Court court) async {
    await _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(court.id)
        .update(court.toFirestore());
  }

  // Eliminar una pista
  Future<void> deleteCourt(String clubId, String courtId) async {
    await _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('courts')
        .doc(courtId)
        .delete();
  }
}
