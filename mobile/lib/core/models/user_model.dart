import 'outlet_model.dart';

class UserModel {
  final int id;
  final String nama;
  final String kodeSpg;
  final String username;
  final String role;
  final int? outletId;
  final OutletModel? outlet;

  const UserModel({
    required this.id,
    required this.nama,
    required this.kodeSpg,
    required this.username,
    required this.role,
    this.outletId,
    this.outlet,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nama: json['nama'] as String,
      kodeSpg: json['kode_spg'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      outletId: json['outlet_id'] as int?,
      outlet: json['outlet'] != null
          ? OutletModel.fromJson(json['outlet'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'kode_spg': kodeSpg,
      'username': username,
      'role': role,
      'outlet_id': outletId,
      'outlet': outlet?.toJson(),
    };
  }
}
