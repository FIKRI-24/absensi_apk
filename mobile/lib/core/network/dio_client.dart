import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../errors/app_exception.dart';
import '../models/attendance_model.dart';
import '../models/outlet_model.dart';
import '../../features/auth/models/login_response.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: ApiConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token tidak valid / kadaluarsa
          _storage.delete(key: ApiConstants.tokenKey);
        }
        handler.next(error);
      },
    ));
    _initialized = true;
  }

  AppException _handleError(DioException e) {
    final message = e.response?.data?['message'] as String? ??
        'Terjadi kesalahan jaringan. Periksa koneksi internet Anda.';
    return AppException(message: message, statusCode: e.response?.statusCode);
  }

  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );
      return LoginResponse.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<OutletModel> getOutlet() async {
    try {
      final response = await _dio.get(ApiConstants.outletMe);
      return OutletModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getServerTime() async {
    try {
      final response = await _dio.get(ApiConstants.serverTime);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AttendanceModel> checkin({
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool mockLocationDetected,
    String? fotoBase64,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.checkin,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'mock_location_detected': mockLocationDetected,
          if (fotoBase64 != null) 'foto_base64': fotoBase64,
        },
      );
      return AttendanceModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AttendanceModel> checkout({
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool mockLocationDetected,
    String? fotoBase64,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.checkout,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'mock_location_detected': mockLocationDetected,
          if (fotoBase64 != null) 'foto_base64': fotoBase64,
        },
      );
      return AttendanceModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<AttendanceModel>> getHistory({String? from, String? to}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;

      final response = await _dio.get(
        ApiConstants.history,
        queryParameters: queryParams,
      );
      final list = response.data['data'] as List<dynamic>;
      return list
          .map((item) => AttendanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
