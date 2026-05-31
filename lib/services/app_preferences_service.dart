import 'package:shared_preferences/shared_preferences.dart';

/// Τοπικές ρυθμίσεις εφαρμογής (PWA, Android, iOS).
class AppPreferencesService {
  AppPreferencesService._();

  static final AppPreferencesService instance = AppPreferencesService._();

  static const String _countdownBadgeKey = 'expiry_countdown_badge';
  static const String _onboardingCompletedKey = 'onboarding_completed_v1';
  static const String _featureTourCompletedKey = 'feature_tour_completed_v1';

  bool _countdownBadge = false;
  bool _onboardingCompleted = false;
  bool _featureTourCompleted = false;
  bool _loaded = false;

  bool get countdownBadge => _countdownBadge;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get featureTourCompleted => _featureTourCompleted;
  bool get isLoaded => _loaded;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _countdownBadge = prefs.getBool(_countdownBadgeKey) ?? false;
    _onboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
    _featureTourCompleted = prefs.getBool(_featureTourCompletedKey) ?? false;
    _loaded = true;
  }

  Future<void> setCountdownBadge(bool value) async {
    _countdownBadge = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_countdownBadgeKey, value);
  }

  Future<void> setOnboardingCompleted(bool value) async {
    _onboardingCompleted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, value);
  }

  Future<void> resetOnboarding() async {
    await setOnboardingCompleted(false);
  }

  Future<void> setFeatureTourCompleted(bool value) async {
    _featureTourCompleted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureTourCompletedKey, value);
  }

  Future<void> resetFeatureTour() async {
    await setFeatureTourCompleted(false);
  }
}
