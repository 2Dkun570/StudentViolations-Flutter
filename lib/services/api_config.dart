import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    final configured = _configuredBaseUrl.trim();
    final baseUrl = configured.isNotEmpty
        ? configured
        : kIsWeb
        ? 'http://localhost:5277'
        : 'http://10.131.40.11:5277';

    return baseUrl.replaceFirst(RegExp(r'/+$'), '');
  }
}
