import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static FirebaseRemoteConfig? _remoteConfig;

  // Initialize Remote Config with default values and fetch settings
  static Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;

    // Set default values
    await _remoteConfig!.setDefaults({'default_club_id': ''});

    // Configure fetch settings
    await _remoteConfig!.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Fetch and activate
    try {
      await _remoteConfig!.fetchAndActivate();
    } catch (e) {
      // If fetch fails, we'll use the cached values or defaults
      // This ensures the app still works offline
    }
  }

  // Get the default club ID from Remote Config
  static String getDefaultClubId() {
    if (_remoteConfig == null) {
      return '';
    }
    return _remoteConfig!.getString('default_club_id');
  }

  // For testing purposes - allows injecting a mock instance
  static void setInstanceForTesting(FirebaseRemoteConfig instance) {
    _remoteConfig = instance;
  }

  // Reset instance (useful for testing)
  static void resetForTesting() {
    _remoteConfig = null;
  }
}
