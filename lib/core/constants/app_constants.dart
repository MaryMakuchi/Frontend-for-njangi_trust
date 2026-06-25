class AppConstants {
  AppConstants._();

  /// Set to true to use local mock data instead of the Django API.
  static const bool useMockData = false;

  /// Deployed backend used by release/test builds (Render).
  static const String _prodApiBaseUrl =
      'https://njangi-trust-api.onrender.com/api/v1';

  /// API base URL.
  ///
  /// Defaults to the deployed backend so distributed APKs work on real
  /// devices out of the box. Override at build/run time for local dev:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
  static String get apiBaseUrl {
    if (useMockData) return 'https://api.njangitrust.com/v1';
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return _prodApiBaseUrl;
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

  static const List<Map<String, String>> countryCodes = [
    {'code': '+237', 'flag': '🇨🇲', 'name': 'Cameroon'},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
    {'code': '+233', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': '+225', 'flag': '🇨🇮', 'name': "Côte d'Ivoire"},
    {'code': '+221', 'flag': '🇸🇳', 'name': 'Senegal'},
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+27', 'flag': '🇿🇦', 'name': 'South Africa'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'United States'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
  ];
}
