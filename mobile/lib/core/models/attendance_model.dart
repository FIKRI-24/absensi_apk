class AttendanceModel {
  final int id;
  final int userId;
  final int outletId;
  final String jenis;
  final DateTime waktuServer;
  final double? latDevice;
  final double? longDevice;
  final double? jarakMeter;
  final bool mockLocationDetected;
  final String status;
  final DateTime createdAt;

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.outletId,
    required this.jenis,
    required this.waktuServer,
    this.latDevice,
    this.longDevice,
    this.jarakMeter,
    required this.mockLocationDetected,
    required this.status,
    required this.createdAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      outletId: json['outlet_id'] as int,
      jenis: json['jenis'] as String,
      waktuServer: DateTime.parse(json['waktu_server'] as String),
      latDevice: json['lat_device'] != null
          ? (json['lat_device'] as num).toDouble()
          : null,
      longDevice: json['long_device'] != null
          ? (json['long_device'] as num).toDouble()
          : null,
      jarakMeter: json['jarak_meter'] != null
          ? (json['jarak_meter'] as num).toDouble()
          : null,
      mockLocationDetected: json['mock_location_detected'] as bool,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
