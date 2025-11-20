import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:padelhub/services/club_service.dart';
import 'package:padelhub/models/club.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ClubService clubService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    clubService = ClubService(firestore: fakeFirestore);
  });

  group('ClubService', () {
    test('getDefaultClub returns first club when clubs exist', () async {
      // Arrange
      await fakeFirestore.collection('clubs').doc('club1').set({
        'name': 'Test Club 1',
        'timezone': 'Europe/Madrid',
        'address': 'Test Address 1',
        'opens_at': '08:00',
        'closes_at': '23:00',
        'has_parking': true,
      });

      await fakeFirestore.collection('clubs').doc('club2').set({
        'name': 'Test Club 2',
        'timezone': 'Europe/Madrid',
      });

      // Act
      final club = await clubService.getDefaultClub();

      // Assert
      expect(club, isNotNull);
      expect(club!.name, isNotEmpty);
      expect(club.timezone, 'Europe/Madrid');
    });

    test('getDefaultClub returns null when no clubs exist', () async {
      // Act
      final club = await clubService.getDefaultClub();

      // Assert
      expect(club, isNull);
    });

    test('getClubs returns stream of clubs', () async {
      // Arrange
      await fakeFirestore.collection('clubs').doc('club1').set({
        'name': 'Club 1',
        'timezone': 'Europe/Madrid',
      });

      await fakeFirestore.collection('clubs').doc('club2').set({
        'name': 'Club 2',
        'timezone': 'Europe/London',
      });

      // Act
      final stream = clubService.getClubs();

      // Assert
      await expectLater(
        stream,
        emits(
          predicate<List<Club>>((clubs) {
            return clubs.length == 2 &&
                clubs.any((c) => c.name == 'Club 1') &&
                clubs.any((c) => c.name == 'Club 2');
          }),
        ),
      );
    });

    test('createClub adds club to firestore', () async {
      // Act
      await clubService.createClub(
        id: 'new-club',
        name: 'New Club',
        timezone: 'Europe/Madrid',
        address: 'New Address',
        opensAt: '09:00',
        closesAt: '22:00',
        hasParking: true,
        hasCafeteria: true,
      );

      // Assert
      final doc = await fakeFirestore.collection('clubs').doc('new-club').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['name'], 'New Club');
      expect(doc.data()?['has_parking'], isTrue);
      expect(doc.data()?['has_cafeteria'], isTrue);
    });

    test('updateClub updates existing club', () async {
      // Arrange
      await fakeFirestore.collection('clubs').doc('club1').set({
        'name': 'Original Name',
        'timezone': 'Europe/Madrid',
      });

      final club = Club(
        id: 'club1',
        name: 'Updated Name',
        timezone: 'Europe/London',
        hasParking: true,
      );

      // Act
      await clubService.updateClub(club);

      // Assert
      final doc = await fakeFirestore.collection('clubs').doc('club1').get();
      expect(doc.data()?['name'], 'Updated Name');
      expect(doc.data()?['timezone'], 'Europe/London');
      expect(doc.data()?['has_parking'], isTrue);
    });

    test('deleteClub removes club and its courts', () async {
      // Arrange
      await fakeFirestore.collection('clubs').doc('club1').set({
        'name': 'Club to Delete',
        'timezone': 'Europe/Madrid',
      });

      await fakeFirestore
          .collection('clubs')
          .doc('club1')
          .collection('courts')
          .doc('court1')
          .set({'name': 'Court 1'});

      // Act
      await clubService.deleteClub('club1');

      // Assert
      final clubDoc = await fakeFirestore
          .collection('clubs')
          .doc('club1')
          .get();
      expect(clubDoc.exists, isFalse);

      final courtsSnapshot = await fakeFirestore
          .collection('clubs')
          .doc('club1')
          .collection('courts')
          .get();
      expect(courtsSnapshot.docs, isEmpty);
    });

    test('isUserAdmin returns true for admin user', () async {
      // Arrange
      await fakeFirestore.collection('users').doc('admin-user').set({
        'email': 'admin@test.com',
        'isAdmin': true,
      });

      // Act
      final isAdmin = await clubService.isUserAdmin('admin-user');

      // Assert
      expect(isAdmin, isTrue);
    });

    test('isUserAdmin returns false for non-admin user', () async {
      // Arrange
      await fakeFirestore.collection('users').doc('regular-user').set({
        'email': 'user@test.com',
        'isAdmin': false,
      });

      // Act
      final isAdmin = await clubService.isUserAdmin('regular-user');

      // Assert
      expect(isAdmin, isFalse);
    });

    test('isUserAdmin returns false for non-existent user', () async {
      // Act
      final isAdmin = await clubService.isUserAdmin('non-existent');

      // Assert
      expect(isAdmin, isFalse);
    });
  });
}
