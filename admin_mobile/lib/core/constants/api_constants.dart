import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    // Android emulator uses 10.0.2.2 to access host machine localhost
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    // iOS simulator / Desktop uses localhost
    return 'http://localhost:5000/api';
  }

  static const String loginEndpoint = '/auth/login';
  static const String usersEndpoint = '/users';
  static const String dashboardStatsEndpoint = '/dashboard/stats';
}
