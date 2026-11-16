import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Memeriksa apakah layanan GPS / lokasi perangkat aktif
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Memeriksa status izin lokasi saat ini
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Meminta izin lokasi ke pengguna
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Mengambil posisi GPS perangkat saat ini dengan akurasi tinggi
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit = const Duration(seconds: 15),
  }) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak secara permanen. Silakan aktifkan izin lokasi melalui Pengaturan Aplikasi.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      ),
    );
  }

  /// Menghitung jarak (dalam meter) antara dua titik koordinat
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Membuka pengaturan lokasi perangkat
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Membuka pengaturan izin aplikasi
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
