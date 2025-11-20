import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:padelhub/services/remote_config_service.dart';

// Generate mocks
@GenerateMocks([FirebaseRemoteConfig])
import 'remote_config_service_test.mocks.dart';

void main() {
  late MockFirebaseRemoteConfig mockRemoteConfig;

  setUp(() {
    mockRemoteConfig = MockFirebaseRemoteConfig();
    RemoteConfigService.resetForTesting();
  });

  tearDown(() {
    RemoteConfigService.resetForTesting();
  });

  group('RemoteConfigService', () {
    test('getDefaultClubId returns empty string when not initialized', () {
      // Act
      final clubId = RemoteConfigService.getDefaultClubId();

      // Assert
      expect(clubId, isEmpty);
    });

    test('getDefaultClubId returns configured club ID', () {
      // Arrange
      when(
        mockRemoteConfig.getString('default_club_id'),
      ).thenReturn('test-club-123');
      RemoteConfigService.setInstanceForTesting(mockRemoteConfig);

      // Act
      final clubId = RemoteConfigService.getDefaultClubId();

      // Assert
      expect(clubId, 'test-club-123');
      verify(mockRemoteConfig.getString('default_club_id')).called(1);
    });

    test('getDefaultClubId returns empty string when value is not set', () {
      // Arrange
      when(mockRemoteConfig.getString('default_club_id')).thenReturn('');
      RemoteConfigService.setInstanceForTesting(mockRemoteConfig);

      // Act
      final clubId = RemoteConfigService.getDefaultClubId();

      // Assert
      expect(clubId, isEmpty);
    });
  });
}
