import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstants {
  ApiConstants._();

  /// URL Base API Backend
  /// - Web / Windows Desktop: http://localhost:5000/api
  /// - Android Emulator: http://10.0.2.2:5000/api
  /// - HP Android Fisik: ganti dengan IP lokal laptop (misal: http://192.168.1.10:5000/api)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }
  static const String login = '/auth/login';
  static const String outletMe = '/outlet/me';
  static const String serverTime = '/server-time';
  static const String checkin = '/attendance/checkin';
  static const String checkout = '/attendance/checkout';
  static const String history = '/attendance/history';
  static const String tokenKey = 'jwt_token';
  static const String userDataKey = 'user_data';
}
