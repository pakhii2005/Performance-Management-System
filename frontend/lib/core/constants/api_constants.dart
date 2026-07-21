
import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kDebugMode) {
      return 'http://localhost:8080';
    }
    return 'https://performance-management-system-1-91w0.onrender.com';
  }

  static const String healthCheckEndpoint = '/api/health';
}
