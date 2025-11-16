import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/models/court.dart';

void main() {
  group('Court Model Tests', () {
    test(
      'should create Court instance with all boolean fields true by default',
      () {
        final court = Court(
          id: 'court123',
          name: 'Pista 1',
          surface: 'Césped artificial',
          description: 'Test court',
        );

        expect(court.id, 'court123');
        expect(court.name, 'Pista 1');
        expect(court.surface, 'Césped artificial');
        expect(court.description, 'Test court');
        expect(court.indoor, isTrue);
        expect(court.hasLighting, isTrue);
        expect(court.hasAirConditioning, isTrue);
      },
    );

    test('should create Court instance with explicit boolean values', () {
      final court = Court(
        id: 'court123',
        name: 'Pista 2',
        surface: 'Cemento',
        description: 'Outdoor court',
        indoor: false,
        hasLighting: false,
        hasAirConditioning: false,
      );

      expect(court.indoor, isFalse);
      expect(court.hasLighting, isFalse);
      expect(court.hasAirConditioning, isFalse);
    });

    test('should create Court instance with mixed boolean values', () {
      final court = Court(
        id: 'court123',
        name: 'Pista 3',
        surface: 'Cristal',
        description: 'Mixed features',
        indoor: true,
        hasLighting: false,
        hasAirConditioning: true,
      );

      expect(court.indoor, isTrue);
      expect(court.hasLighting, isFalse);
      expect(court.hasAirConditioning, isTrue);
    });

    test('should serialize Court to Firestore format with all fields', () {
      final court = Court(
        id: 'court123',
        name: 'Pista 1',
        surface: 'Césped artificial',
        description: 'Test court',
        indoor: true,
        hasLighting: true,
        hasAirConditioning: true,
      );

      final firestoreData = court.toFirestore();

      expect(firestoreData['name'], 'Pista 1');
      expect(firestoreData['surface'], 'Césped artificial');
      expect(firestoreData['description'], 'Test court');
      expect(firestoreData['indoor'], isTrue);
      expect(firestoreData['has_lighting'], isTrue);
      expect(firestoreData['has_air_conditioning'], isTrue);
    });

    test('should serialize Court with false boolean values', () {
      final court = Court(
        id: 'court123',
        name: 'Pista 2',
        surface: 'Cemento',
        description: 'Outdoor court',
        indoor: false,
        hasLighting: false,
        hasAirConditioning: false,
      );

      final firestoreData = court.toFirestore();

      expect(firestoreData['indoor'], isFalse);
      expect(firestoreData['has_lighting'], isFalse);
      expect(firestoreData['has_air_conditioning'], isFalse);
    });

    test('should deserialize Court from Firestore snapshot', () {
      final mockData = {
        'name': 'Pista 1',
        'surface': 'Césped artificial',
        'description': 'Test court',
        'indoor': true,
        'has_lighting': true,
        'has_air_conditioning': true,
      };

      final court = Court.fromFirestore('court123', mockData);

      expect(court.id, 'court123');
      expect(court.name, 'Pista 1');
      expect(court.surface, 'Césped artificial');
      expect(court.description, 'Test court');
      expect(court.indoor, isTrue);
      expect(court.hasLighting, isTrue);
      expect(court.hasAirConditioning, isTrue);
    });

    test('should deserialize Court with false boolean values', () {
      final mockData = {
        'name': 'Pista 2',
        'surface': 'Cemento',
        'description': 'Outdoor court',
        'indoor': false,
        'has_lighting': false,
        'has_air_conditioning': false,
      };

      final court = Court.fromFirestore('court123', mockData);

      expect(court.indoor, isFalse);
      expect(court.hasLighting, isFalse);
      expect(court.hasAirConditioning, isFalse);
    });

    test(
      'should handle round-trip serialization/deserialization with default values',
      () {
        final originalCourt = Court(
          id: 'court123',
          name: 'Pista 1',
          surface: 'Césped artificial',
          description: 'Test court',
        );

        final firestoreData = originalCourt.toFirestore();
        final deserializedCourt = Court.fromFirestore(
          'court123',
          firestoreData,
        );

        expect(deserializedCourt.id, originalCourt.id);
        expect(deserializedCourt.name, originalCourt.name);
        expect(deserializedCourt.surface, originalCourt.surface);
        expect(deserializedCourt.description, originalCourt.description);
        expect(deserializedCourt.indoor, originalCourt.indoor);
        expect(deserializedCourt.hasLighting, originalCourt.hasLighting);
        expect(
          deserializedCourt.hasAirConditioning,
          originalCourt.hasAirConditioning,
        );
      },
    );

    test(
      'should handle round-trip serialization/deserialization with explicit false values',
      () {
        final originalCourt = Court(
          id: 'court123',
          name: 'Pista 2',
          surface: 'Cemento',
          description: 'Outdoor court',
          indoor: false,
          hasLighting: false,
          hasAirConditioning: false,
        );

        final firestoreData = originalCourt.toFirestore();
        final deserializedCourt = Court.fromFirestore(
          'court123',
          firestoreData,
        );

        expect(deserializedCourt.id, originalCourt.id);
        expect(deserializedCourt.indoor, isFalse);
        expect(deserializedCourt.hasLighting, isFalse);
        expect(deserializedCourt.hasAirConditioning, isFalse);
      },
    );

    test('should handle missing air conditioning field in legacy data', () {
      final mockData = {
        'name': 'Pista Legacy',
        'surface': 'Césped artificial',
        'description': 'Legacy court without AC field',
        'indoor': true,
        'has_lighting': true,
        // has_air_conditioning is missing
      };

      final court = Court.fromFirestore('court123', mockData);

      expect(court.id, 'court123');
      expect(court.name, 'Pista Legacy');
      expect(court.indoor, isTrue);
      expect(court.hasLighting, isTrue);
      // Should default to true when missing (as per model defaults)
      expect(court.hasAirConditioning, isTrue);
    });
  });
}
