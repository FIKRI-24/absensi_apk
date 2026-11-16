import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/outlet_model.dart';
import '../../../core/services/location_service.dart';

enum LocationStatus {
  initial,
  loading,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

class LocationState {
  final LocationStatus status;
  final Position? position;
  final double? distanceMeters;
  final bool isWithinRadius;
  final bool isMocked;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const LocationState({
    this.status = LocationStatus.initial,
    this.position,
    this.distanceMeters,
    this.isWithinRadius = false,
    this.isMocked = false,
    this.errorMessage,
    this.lastUpdated,
  });

  bool get isLoading => status == LocationStatus.loading;
  bool get isReady => status == LocationStatus.ready && position != null;

  LocationState copyWith({
    LocationStatus? status,
    Position? position,
    double? distanceMeters,
    bool? isWithinRadius,
    bool? isMocked,
    String? errorMessage,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      position: position ?? this.position,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      isWithinRadius: isWithinRadius ?? this.isWithinRadius,
      isMocked: isMocked ?? this.isMocked,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier({LocationService? locationService})
      : _locationService = locationService ?? LocationService(),
        super(const LocationState());

  Future<void> refreshLocation({required OutletModel? outlet}) async {
    state = state.copyWith(
      status: LocationStatus.loading,
      clearError: true,
    );

    try {
      // 1. Periksa apakah GPS aktif
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          status: LocationStatus.serviceDisabled,
          errorMessage: 'Layanan lokasi (GPS) pada perangkat tidak aktif.',
        );
        return;
      }

      // 2. Periksa dan minta izin lokasi
      var permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            status: LocationStatus.permissionDenied,
            errorMessage: 'Izin lokasi diperlukan untuk melakukan absensi.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          status: LocationStatus.permissionDeniedForever,
          errorMessage:
              'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk memberikan izin.',
        );
        return;
      }

      // 3. Ambil koordinat GPS saat ini
      final position = await _locationService.getCurrentPosition();

      // 4. Hitung jarak jika outlet tersedia
      double? distance;
      bool withinRadius = false;

      if (outlet != null) {
        distance = _locationService.calculateDistance(
          startLatitude: position.latitude,
          startLongitude: position.longitude,
          endLatitude: outlet.latitude,
          endLongitude: outlet.longitude,
        );
        withinRadius = distance <= outlet.radiusMeter;
      }

      // 5. Cek apakah lokasi palsu / mock GPS terdeteksi
      final isMockLocation = position.isMocked;

      state = state.copyWith(
        status: LocationStatus.ready,
        position: position,
        distanceMeters: distance,
        isWithinRadius: withinRadius,
        isMocked: isMockLocation,
        lastUpdated: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: LocationStatus.error,
        errorMessage: 'Gagal memperbarui lokasi: ${e.toString()}',
      );
    }
  }

  Future<void> openSettings() async {
    if (state.status == LocationStatus.serviceDisabled) {
      await _locationService.openLocationSettings();
    } else {
      await _locationService.openAppSettings();
    }
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
