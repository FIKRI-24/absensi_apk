import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/outlet_model.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/features/location/providers/location_provider.dart';

void main() {
  group('LocationService & Distance Tests', () {
    final locationService = LocationService();

    test('calculateDistance should return near 0 for identical coordinates', () {
      final distance = locationService.calculateDistance(
        startLatitude: -6.19515,
        startLongitude: 106.82088,
        endLatitude: -6.19515,
        endLongitude: 106.82088,
      );
      expect(distance, closeTo(0.0, 1.0));
    });

    test('calculateDistance should calculate accurate distance between known points', () {
      // Grand Indonesia (-6.19515, 106.82088) to Monas (-6.17539, 106.82715) ~ 2.3 km
      final distance = locationService.calculateDistance(
        startLatitude: -6.19515,
        startLongitude: 106.82088,
        endLatitude: -6.17539,
        endLongitude: 106.82715,
      );
      expect(distance, greaterThan(2000));
      expect(distance, lessThan(2500));
    });
  });

  group('LocationState Unit Tests', () {
    test('default state should have initial status and no position', () {
      const state = LocationState();
      expect(state.status, LocationStatus.initial);
      expect(state.position, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isReady, isFalse);
      expect(state.isWithinRadius, isFalse);
      expect(state.isMocked, isFalse);
    });

    test('copyWith updates state values accurately', () {
      const state = LocationState();
      final updated = state.copyWith(
        status: LocationStatus.ready,
        distanceMeters: 45.5,
        isWithinRadius: true,
        isMocked: false,
      );

      expect(updated.status, LocationStatus.ready);
      expect(updated.distanceMeters, 45.5);
      expect(updated.isWithinRadius, isTrue);
      expect(updated.isMocked, isFalse);
    });

    test('outlet radius check verification', () {
      final outlet = OutletModel(
        id: 1,
        namaToko: 'Grand Indonesia',
        kodeOutlet: 'OUT-GI-01',
        latitude: -6.19515,
        longitude: 106.82088,
        radiusMeter: 100,
      );

      final locationService = LocationService();
      
      // Titik di dalam radius 100m (~15m dari toko)
      final insideDistance = locationService.calculateDistance(
        startLatitude: -6.19525,
        startLongitude: 106.82088,
        endLatitude: outlet.latitude,
        endLongitude: outlet.longitude,
      );
      expect(insideDistance <= outlet.radiusMeter, isTrue);

      // Titik di luar radius 100m (~2.3km dari toko)
      final outsideDistance = locationService.calculateDistance(
        startLatitude: -6.17539,
        startLongitude: 106.82715,
        endLatitude: outlet.latitude,
        endLongitude: outlet.longitude,
      );
      expect(outsideDistance <= outlet.radiusMeter, isFalse);
    });
  });
}
