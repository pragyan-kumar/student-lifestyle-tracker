import 'package:flutter/foundation.dart' show kIsWeb;

/// App-wide constants.
class AppConstants {
  AppConstants._();

  // ── API ─────────────────────────────────────────────────────────────────
  /// On web/desktop use localhost; on Android emulator use 10.0.2.2.
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    return kIsWeb ? 'http://localhost:5001/api/v1' : 'http://10.0.2.2:5001/api/v1';
  }
  static const String carbonInterfaceUrl  = 'https://www.carboninterface.com/api/v1';
  static const int    connectTimeout      = 30000; // ms
  static const int    receiveTimeout      = 30000;

  // ── Hive Box Names ───────────────────────────────────────────────────────
  static const String habitsBox       = 'habits_box';
  static const String carbonBox       = 'carbon_box';
  static const String userBox         = 'user_box';
  static const String settingsBox     = 'settings_box';
  static const String gamificationBox = 'gamification_box';

  // ── SharedPreferences Keys ───────────────────────────────────────────────
  static const String kIsOnboarded    = 'is_onboarded';
  static const String kThemeMode      = 'theme_mode';
  static const String kAuthToken      = 'auth_token';

  // ── Gamification ─────────────────────────────────────────────────────────
  static const int pointsSleepLog     = 10;
  static const int pointsDietLog      = 10;
  static const int pointsExerciseLog  = 15;
  static const int pointsLowCarbon    = 20;
  static const int pointsStreakBonus  = 50;

  // ── Carbon Emission Factors (kg CO₂ per unit) ────────────────────────────
  // Source: Carbon Interface API defaults (standardised emission factors)
  static const Map<String, double> commuteEmissions = {
    'walk'        : 0.0,
    'bicycle'     : 0.0,
    'metro'       : 0.041,  // kg CO₂/km
    'bus'         : 0.089,
    'auto'        : 0.143,
    'bike'        : 0.113,
    'car_petrol'  : 0.192,
    'car_diesel'  : 0.171,
  };

  static const Map<String, double> mealEmissions = {
    'vegan'       : 1.5,   // kg CO₂/day
    'vegetarian'  : 2.5,
    'mixed'       : 4.5,
    'meat_heavy'  : 7.2,
  };

  // ── Sleep Thresholds (hours) ─────────────────────────────────────────────
  static const double minHealthySleep  = 6.0;
  static const double maxHealthySleep  = 9.0;
  static const double optimalSleep     = 8.0;

  // ── Screen Time Thresholds (hours) ──────────────────────────────────────
  static const double maxScreenTime    = 4.0;

  // ── Exercise Targets ────────────────────────────────────────────────────
  static const int minExerciseMinsPerDay = 30;
}
