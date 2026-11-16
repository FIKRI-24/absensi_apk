import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/attendance_model.dart';
import 'package:mobile/features/attendance/providers/attendance_provider.dart';

void main() {
  group('AttendanceModel Tests', () {
    test('AttendanceModel.fromJson parse data correctly', () {
      final json = {
        'id': 10,
        'user_id': 2,
        'outlet_id': 1,
        'jenis': 'masuk',
        'waktu_server': '2026-11-16T08:30:00.000Z',
        'lat_device': -6.19515,
        'long_device': 106.82088,
        'jarak_meter': 25.5,
        'mock_location_detected': false,
        'status': 'valid',
        'created_at': '2026-11-16T08:30:00.000Z',
      };

      final model = AttendanceModel.fromJson(json);

      expect(model.id, 10);
      expect(model.userId, 2);
      expect(model.outletId, 1);
      expect(model.jenis, 'masuk');
      expect(model.jarakMeter, 25.5);
      expect(model.mockLocationDetected, isFalse);
      expect(model.status, 'valid');
    });
  });

  group('AttendanceState Tests', () {
    test('Initial attendance state should have empty history and not submitting', () {
      const state = AttendanceState();
      expect(state.isSubmitting, isFalse);
      expect(state.isLoadingHistory, isFalse);
      expect(state.history, isEmpty);
      expect(state.todayCheckin, isNull);
      expect(state.todayCheckout, isNull);
      expect(state.hasCheckedInToday, isFalse);
      expect(state.hasCheckedOutToday, isFalse);
    });

    test('AttendanceState detects today checkin and checkout correctly', () {
      final today = DateTime.now();
      final checkin = AttendanceModel(
        id: 1,
        userId: 2,
        outletId: 1,
        jenis: 'masuk',
        waktuServer: today,
        mockLocationDetected: false,
        status: 'valid',
        createdAt: today,
      );

      final checkout = AttendanceModel(
        id: 2,
        userId: 2,
        outletId: 1,
        jenis: 'pulang',
        waktuServer: today,
        mockLocationDetected: false,
        status: 'valid',
        createdAt: today,
      );

      final state = AttendanceState(
        todayCheckin: checkin,
        todayCheckout: checkout,
      );

      expect(state.hasCheckedInToday, isTrue);
      expect(state.hasCheckedOutToday, isTrue);
    });
  });
}
