class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:5000/api';
  static const String login = '/auth/login';
  static const String outletMe = '/outlet/me';
  static const String serverTime = '/server-time';
  static const String checkin = '/attendance/checkin';
  static const String checkout = '/attendance/checkout';
  static const String history = '/attendance/history';
  static const String tokenKey = 'jwt_token';
  static const String userDataKey = 'user_data';
}
