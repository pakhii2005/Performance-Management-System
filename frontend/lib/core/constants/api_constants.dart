import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstants {
  static String get baseUrl => 'http://192.168.1.3:8080';

  static const String healthCheckEndpoint = '/api/health';
}
