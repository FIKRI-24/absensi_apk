import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/network/dio_client.dart';

class AttendanceResult {
  final bool success;
  final String message;
  final AttendanceModel? attendance;

  const AttendanceResult({
    required this.success,
    required this.message,
    this.attendance,
  });
}

class AttendanceState {
  final bool isSubmitting;
  final bool isLoadingHistory;
  final List<AttendanceModel> history;
  final AttendanceModel? todayCheckin;
  final AttendanceModel? todayCheckout;
  final String? errorMessage;
  final String? successMessage;

  const AttendanceState({
    this.isSubmitting = false,
    this.isLoadingHistory = false,
    this.history = const [],
    this.todayCheckin,
    this.todayCheckout,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasCheckedInToday => todayCheckin != null;
  bool get hasCheckedOutToday => todayCheckout != null;

  AttendanceState copyWith({
    bool? isSubmitting,
    bool? isLoadingHistory,
    List<AttendanceModel>? history,
    AttendanceModel? todayCheckin,
    AttendanceModel? todayCheckout,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AttendanceState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      history: history ?? this.history,
      todayCheckin: todayCheckin ?? this.todayCheckin,
      todayCheckout: todayCheckout ?? this.todayCheckout,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final DioClient _dioClient;

  AttendanceNotifier({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient(),
        super(const AttendanceState());

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  void _deriveTodayStatus(List<AttendanceModel> historyList) {
    AttendanceModel? checkin;
    AttendanceModel? checkout;

    for (final item in historyList) {
      if (_isToday(item.waktuServer)) {
        if (item.jenis == 'masuk' && checkin == null) {
          checkin = item;
        } else if (item.jenis == 'pulang' && checkout == null) {
          checkout = item;
        }
      }
    }

    state = state.copyWith(
      history: historyList,
      todayCheckin: checkin,
      todayCheckout: checkout,
      isLoadingHistory: false,
    );
  }

  Future<void> fetchHistory({String? from, String? to}) async {
    state = state.copyWith(isLoadingHistory: true, clearError: true);
    try {
      final list = await _dioClient.getHistory(from: from, to: to);
      _deriveTodayStatus(list);
    } on AppException catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        errorMessage: 'Gagal memuat riwayat absensi: ${e.toString()}',
      );
    }
  }

  Future<AttendanceResult> checkin({
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool mockLocationDetected,
    String? fotoBase64,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final attendance = await _dioClient.checkin(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        mockLocationDetected: mockLocationDetected,
        fotoBase64: fotoBase64,
      );

      final updatedHistory = [attendance, ...state.history];
      _deriveTodayStatus(updatedHistory);

      state = state.copyWith(
        isSubmitting: false,
        todayCheckin: attendance,
        successMessage: 'Absen Datang berhasil dicatat!',
      );

      return AttendanceResult(
        success: true,
        message: 'Absen Datang berhasil dicatat!',
        attendance: attendance,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return AttendanceResult(success: false, message: e.message);
    } catch (e) {
      final msg = 'Terjadi kesalahan saat absen datang: ${e.toString()}';
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: msg,
      );
      return AttendanceResult(success: false, message: msg);
    }
  }

  Future<AttendanceResult> checkout({
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool mockLocationDetected,
    String? fotoBase64,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final attendance = await _dioClient.checkout(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        mockLocationDetected: mockLocationDetected,
        fotoBase64: fotoBase64,
      );

      final updatedHistory = [attendance, ...state.history];
      _deriveTodayStatus(updatedHistory);

      state = state.copyWith(
        isSubmitting: false,
        todayCheckout: attendance,
        successMessage: 'Absen Pulang berhasil dicatat!',
      );

      return AttendanceResult(
        success: true,
        message: 'Absen Pulang berhasil dicatat!',
        attendance: attendance,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return AttendanceResult(success: false, message: e.message);
    } catch (e) {
      final msg = 'Terjadi kesalahan saat absen pulang: ${e.toString()}';
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: msg,
      );
      return AttendanceResult(success: false, message: msg);
    }
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier();
});
