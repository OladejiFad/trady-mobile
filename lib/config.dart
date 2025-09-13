// lib/config.dart
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://172.20.10.2:5000', // keep your old local IP as fallback
);
