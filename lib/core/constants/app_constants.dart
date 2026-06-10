import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class AppConstants {
  AppConstants._();

  /// Set to true to use local mock data instead of the Django API.
  static const bool useMockData = false;

  static String get apiBaseUrl {
    if (useMockData) return 'https://api.njangitrust.com/v1';
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  static const Duration apiTimeout = Duration(seconds: 30);
  static const String jwtTokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String pinKey = 'user_pin';
  static const String biometricsEnabledKey = 'biometrics_enabled';

  static const int otpLength = 6;
  static const int pinLength = 4;
  static const int otpResendSeconds = 60;

  static const List<int> quickAmounts = [25000, 50000, 100000, 200000];
  static const List<String> paymentMethods = [
    'MTN MoMo',
    'Orange Money',
    'Njangi Wallet',
    'Bank Transfer',
  ];

  static const List<String> contributionFrequencies = [
    'Weekly',
    'Bi-weekly',
    'Monthly',
  ];
}
