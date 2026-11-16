import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../attendance/screens/history_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../location/providers/location_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  void _refreshAll() {
    final user = ref.read(authProvider).user;
    ref.read(locationProvider.notifier).refreshLocation(outlet: user?.outlet);
    ref.read(attendanceProvider.notifier).fetchHistory();
  }

  Future<void> _onLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(1)} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second WIB';
  }

  Future<void> _handleAttendance({required bool isCheckin}) async {
    final locationState = ref.read(locationProvider);
    final user = ref.read(authProvider).user;
    final outlet = user?.outlet;

    if (!locationState.isReady || locationState.position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi GPS belum siap. Silakan tunggu atau tekan tombol refresh lokasi.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pos = locationState.position!;
    final actionName = isCheckin ? 'Absen Datang' : 'Absen Pulang';
    final distanceText = locationState.distanceMeters != null
        ? _formatDistance(locationState.distanceMeters!)
        : '-';

    // Dialog Konfirmasi (Ya/Tidak) sesuai PRD
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isCheckin ? Icons.login_rounded : Icons.logout_rounded,
              color: isCheckin ? Colors.green.shade700 : Colors.blue.shade700,
            ),
            const SizedBox(width: 10),
            Text('Konfirmasi $actionName'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin melakukan $actionName sekarang?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _DialogRow(
                    label: 'Toko Bertugas',
                    value: outlet?.namaToko ?? '-',
                  ),
                  const SizedBox(height: 6),
                  _DialogRow(
                    label: 'Jarak ke Toko',
                    value: distanceText,
                  ),
                  const SizedBox(height: 6),
                  _DialogRow(
                    label: 'Status Radius',
                    value: locationState.isWithinRadius
                        ? 'Di Dalam Radius'
                        : 'Di Luar Radius Toko',
                    valueColor: locationState.isWithinRadius
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tidak / Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCheckin ? Colors.green.shade700 : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Kirim Absen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Kirim request ke backend
    final result = isCheckin
        ? await ref.read(attendanceProvider.notifier).checkin(
            latitude: pos.latitude,
            longitude: pos.longitude,
            accuracy: pos.accuracy,
            mockLocationDetected: locationState.isMocked,
          )
        : await ref.read(attendanceProvider.notifier).checkout(
            latitude: pos.latitude,
            longitude: pos.longitude,
            accuracy: pos.accuracy,
            mockLocationDetected: locationState.isMocked,
          );

    if (!mounted) return;

    if (result.success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 52,
          ),
          title: Text('$actionName Berhasil!'),
          content: Text(
            result.message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 52,
          ),
          title: Text('$actionName Ditolak'),
          content: Text(
            result.message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Mengerti',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final locationState = ref.watch(locationProvider);
    final attendanceState = ref.watch(attendanceProvider);
    final user = authState.user;
    final outlet = user?.outlet;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'Absensi SPG',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Absensi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Perbarui Data & Lokasi',
            onPressed:
                locationState.isLoading || attendanceState.isLoadingHistory
                    ? null
                    : _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAll();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Kartu Profil SPG & Toko ──────────────────────────────
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            radius: 26,
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.blue.shade700,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.nama ?? 'SPG',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kode: ${user?.kodeSpg ?? '-'} • ${user?.role.toUpperCase() ?? 'SPG'}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _OutletInfoTile(
                        namaToko: outlet?.namaToko ?? 'Belum Ditugaskan',
                        kodeOutlet: outlet?.kodeOutlet ?? '-',
                        radius: outlet?.radiusMeter ?? 100,
                        latitude: outlet?.latitude,
                        longitude: outlet?.longitude,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 2. Kartu Status GPS & Estimasi Jarak ─────────────────────
              _LocationStatusCard(
                state: locationState,
                outlet: outlet,
                onRefresh: _refreshAll,
                onOpenSettings: () {
                  ref.read(locationProvider.notifier).openSettings();
                },
                formatDistance: _formatDistance,
                formatTime: _formatTime,
              ),
              const SizedBox(height: 16),

              // ── 3. Tombol Aksi Absensi (Datang & Pulang) ─────────────────
              _AttendanceActionCard(
                attendanceState: attendanceState,
                locationState: locationState,
                onCheckin: () => _handleAttendance(isCheckin: true),
                onCheckout: () => _handleAttendance(isCheckin: false),
                formatTime: _formatTime,
              ),
              const SizedBox(height: 16),

              // ── 4. Ringkasan Riwayat Hari Ini ────────────────────────────
              _TodayAttendanceSummary(
                checkin: attendanceState.todayCheckin,
                checkout: attendanceState.todayCheckout,
                onViewAll: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
                formatTime: _formatTime,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DialogRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _OutletInfoTile extends StatelessWidget {
  final String namaToko;
  final String kodeOutlet;
  final int radius;
  final double? latitude;
  final double? longitude;

  const _OutletInfoTile({
    required this.namaToko,
    required this.kodeOutlet,
    required this.radius,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded,
                  color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  namaToko,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  kodeOutlet,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Radius Absen: $radius m',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              if (latitude != null && longitude != null)
                Text(
                  'Koordinat: ${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationStatusCard extends StatelessWidget {
  final LocationState state;
  final dynamic outlet;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSettings;
  final String Function(double) formatDistance;
  final String Function(DateTime) formatTime;

  const _LocationStatusCard({
    required this.state,
    required this.outlet,
    required this.onRefresh,
    required this.onOpenSettings,
    required this.formatDistance,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.my_location_rounded,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Lokasi & Jarak Real-Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (state.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (state.isLoading && state.position == null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Mendeteksi posisi GPS perangkat...',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              )
            else if (state.status == LocationStatus.serviceDisabled ||
                state.status == LocationStatus.permissionDenied ||
                state.status == LocationStatus.permissionDeniedForever)
              _PermissionWarning(
                status: state.status,
                errorMessage: state.errorMessage ?? '',
                onOpenSettings: onOpenSettings,
                onRetry: onRefresh,
              )
            else if (state.status == LocationStatus.error)
              _ErrorWarning(
                errorMessage: state.errorMessage ?? '',
                onRetry: onRefresh,
              )
            else if (state.isReady) ...[
              if (state.isMocked) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'PERINGATAN: Terdeteksi Fake/Mock GPS! Permintaan absen akan ditolak oleh server.',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: state.isWithinRadius
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isWithinRadius
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.isWithinRadius
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: state.isWithinRadius
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isWithinRadius
                                ? 'Di Dalam Radius Absensi'
                                : 'Di Luar Radius Toko',
                            style: TextStyle(
                              color: state.isWithinRadius
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            state.isWithinRadius
                                ? 'Anda berada dalam jarak yang diizinkan untuk absen'
                                : 'Silakan mendekat ke lokasi toko untuk dapat melakukan absen',
                            style: TextStyle(
                              color: state.isWithinRadius
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Jarak ke Toko',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          state.distanceMeters != null
                              ? formatDistance(state.distanceMeters!)
                              : '-',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: state.isWithinRadius
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Koordinat Anda:',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${state.position!.latitude.toStringAsFixed(5)}, ${state.position!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Akurasi GPS:',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          '±${state.position!.accuracy.toStringAsFixed(1)} meter',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (state.lastUpdated != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Diperbarui: ${formatTime(state.lastUpdated!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttendanceActionCard extends StatelessWidget {
  final AttendanceState attendanceState;
  final LocationState locationState;
  final VoidCallback onCheckin;
  final VoidCallback onCheckout;
  final String Function(DateTime) formatTime;

  const _AttendanceActionCard({
    required this.attendanceState,
    required this.locationState,
    required this.onCheckin,
    required this.onCheckout,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final hasCheckin = attendanceState.hasCheckedInToday;
    final hasCheckout = attendanceState.hasCheckedOutToday;
    final isSubmitting = attendanceState.isSubmitting;
    final isGpsReady = locationState.isReady;

    final canCheckin = !hasCheckin && isGpsReady && !isSubmitting;
    final canCheckout = hasCheckin && !hasCheckout && isGpsReady && !isSubmitting;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.touch_app_rounded,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Aksi Absensi Hari Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isSubmitting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Dua Tombol Absen
            Row(
              children: [
                // Tombol Absen Datang
                Expanded(
                  child: ElevatedButton(
                    onPressed: canCheckin ? onCheckin : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: hasCheckin
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                      disabledForegroundColor: hasCheckin
                          ? Colors.green.shade900
                          : Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasCheckin
                              ? Icons.check_circle_rounded
                              : Icons.login_rounded,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasCheckin ? 'Sudah Datang' : 'Absen Datang',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Absen Pulang
                Expanded(
                  child: ElevatedButton(
                    onPressed: canCheckout ? onCheckout : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: hasCheckout
                          ? Colors.blue.shade100
                          : Colors.grey.shade300,
                      disabledForegroundColor: hasCheckout
                          ? Colors.blue.shade900
                          : Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasCheckout
                              ? Icons.check_circle_rounded
                              : Icons.logout_rounded,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasCheckout
                              ? 'Sudah Pulang'
                              : !hasCheckin
                                  ? 'Belum Datang'
                                  : 'Absen Pulang',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayAttendanceSummary extends StatelessWidget {
  final dynamic checkin;
  final dynamic checkout;
  final VoidCallback onViewAll;
  final String Function(DateTime) formatTime;

  const _TodayAttendanceSummary({
    required this.checkin,
    required this.checkout,
    required this.onViewAll,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Kehadiran Hari Ini',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Semua Riwayat >'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: checkin != null
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: checkin != null
                            ? Colors.green.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datang',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checkin != null
                              ? formatTime(checkin.waktuServer)
                              : 'Belum Ada',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: checkin != null
                                ? Colors.green.shade800
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: checkout != null
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: checkout != null
                            ? Colors.blue.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pulang',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checkout != null
                              ? formatTime(checkout.waktuServer)
                              : 'Belum Ada',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: checkout != null
                                ? Colors.blue.shade800
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionWarning extends StatelessWidget {
  final LocationStatus status;
  final String errorMessage;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;

  const _PermissionWarning({
    required this.status,
    required this.errorMessage,
    required this.onOpenSettings,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isServiceDisabled = status == LocationStatus.serviceDisabled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isServiceDisabled
                    ? Icons.location_off_rounded
                    : Icons.security_rounded,
                color: Colors.amber.shade900,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade900,
                  side: BorderSide(color: Colors.amber.shade400),
                ),
                child: const Text('Coba Lagi'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onOpenSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                    isServiceDisabled ? 'Aktifkan GPS' : 'Buka Pengaturan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorWarning extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorWarning({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.red.shade700, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
