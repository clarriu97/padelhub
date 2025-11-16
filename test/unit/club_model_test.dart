import 'package:flutter_test/flutter_test.dart';
import 'package:padelhub/models/club.dart';

void main() {
  group('Club Model Tests', () {
    test('should create Club instance with all fields', () {
      final club = Club(
        id: 'club123',
        name: 'Test Club',
        timezone: 'Europe/Madrid',
        address: 'Calle Test 123',
        opensAt: '08:00',
        closesAt: '23:00',
      );

      expect(club.id, 'club123');
      expect(club.name, 'Test Club');
      expect(club.timezone, 'Europe/Madrid');
      expect(club.address, 'Calle Test 123');
      expect(club.opensAt, '08:00');
      expect(club.closesAt, '23:00');
    });

    test('should create Club instance with null address', () {
      final club = Club(
        id: 'club123',
        name: 'Test Club',
        timezone: 'Europe/Madrid',
        address: null,
        opensAt: '08:00',
        closesAt: '23:00',
      );

      expect(club.id, 'club123');
      expect(club.name, 'Test Club');
      expect(club.address, isNull);
    });

    test('should serialize Club to Firestore format', () {
      final club = Club(
        id: 'club123',
        name: 'Test Club',
        timezone: 'Europe/Madrid',
        address: 'Calle Test 123',
        opensAt: '08:00',
        closesAt: '23:00',
      );

      final firestoreData = club.toFirestore();

      expect(firestoreData['name'], 'Test Club');
      expect(firestoreData['timezone'], 'Europe/Madrid');
      expect(firestoreData['address'], 'Calle Test 123');
      expect(firestoreData['opens_at'], '08:00');
      expect(firestoreData['closes_at'], '23:00');
    });

    test('should serialize Club with null address to Firestore format', () {
      final club = Club(
        id: 'club123',
        name: 'Test Club',
        timezone: 'Europe/Madrid',
        address: null,
        opensAt: '08:00',
        closesAt: '23:00',
      );

      final firestoreData = club.toFirestore();

      expect(firestoreData['name'], 'Test Club');
      expect(firestoreData['address'], isNull);
    });

    test('should deserialize Club from Firestore snapshot', () {
      final mockData = {
        'name': 'Test Club',
        'timezone': 'Europe/Madrid',
        'address': 'Calle Test 123',
        'opens_at': '08:00',
        'closes_at': '23:00',
      };

      final club = Club.fromFirestore('club123', mockData);

      expect(club.id, 'club123');
      expect(club.name, 'Test Club');
      expect(club.timezone, 'Europe/Madrid');
      expect(club.address, 'Calle Test 123');
      expect(club.opensAt, '08:00');
      expect(club.closesAt, '23:00');
    });

    test(
      'should deserialize Club from Firestore snapshot with null address',
      () {
        final mockData = {
          'name': 'Test Club',
          'timezone': 'Europe/Madrid',
          'opens_at': '08:00',
          'closes_at': '23:00',
        };

        final club = Club.fromFirestore('club123', mockData);

        expect(club.id, 'club123');
        expect(club.name, 'Test Club');
        expect(club.address, isNull);
      },
    );

    test(
      'should handle round-trip serialization/deserialization with address',
      () {
        final originalClub = Club(
          id: 'club123',
          name: 'Test Club',
          timezone: 'Europe/Madrid',
          address: 'Calle Test 123',
          opensAt: '08:00',
          closesAt: '23:00',
        );

        final firestoreData = originalClub.toFirestore();
        final deserializedClub = Club.fromFirestore('club123', firestoreData);

        expect(deserializedClub.id, originalClub.id);
        expect(deserializedClub.name, originalClub.name);
        expect(deserializedClub.timezone, originalClub.timezone);
        expect(deserializedClub.address, originalClub.address);
        expect(deserializedClub.opensAt, originalClub.opensAt);
        expect(deserializedClub.closesAt, originalClub.closesAt);
      },
    );

    test(
      'should handle round-trip serialization/deserialization without address',
      () {
        final originalClub = Club(
          id: 'club123',
          name: 'Test Club',
          timezone: 'Europe/Madrid',
          address: null,
          opensAt: '08:00',
          closesAt: '23:00',
        );

        final firestoreData = originalClub.toFirestore();
        final deserializedClub = Club.fromFirestore('club123', firestoreData);

        expect(deserializedClub.id, originalClub.id);
        expect(deserializedClub.name, originalClub.name);
        expect(deserializedClub.address, isNull);
      },
    );
  });
}
