import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstants {
  /// Resolves the base URL dynamically depending on the current platform environment.
  /// Web and iOS simulator can connect directly to localhost, while the Android
  /// emulator needs to route through the loopback address 10.0.2.2.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
    } catch (_) {
      // Safeguard for non-io platform environments where Platform might throw
    }
    return 'http://localhost:8080';
  }

  static const String healthCheckEndpoint = '/api/health';
}
