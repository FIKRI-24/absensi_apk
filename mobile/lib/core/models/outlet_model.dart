class OutletModel {
  final int id;
  final String namaToko;
  final String kodeOutlet;
  final double latitude;
  final double longitude;
  final int radiusMeter;

  const OutletModel({
    required this.id,
    required this.namaToko,
    required this.kodeOutlet,
    required this.latitude,
    required this.longitude,
    required this.radiusMeter,
  });

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    return OutletModel(
      id: json['id'] as int,
      namaToko: json['nama_toko'] as String,
      kodeOutlet: json['kode_outlet'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeter: json['radius_meter'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_toko': namaToko,
      'kode_outlet': kodeOutlet,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meter': radiusMeter,
    };
  }
}
