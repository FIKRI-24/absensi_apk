import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final outlet = user?.outlet;

    Future<void> onLogout() async {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text(
          'Beranda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: onLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Kartu Info SPG ────────────────────────────────────────
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            radius: 26,
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.blue.shade700,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.nama ?? '-',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kode SPG: ${user?.kodeSpg ?? '-'}',
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
                      _InfoRow(
                        icon: Icons.store_rounded,
                        label: 'Outlet',
                        value: outlet?.namaToko ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.tag_rounded,
                        label: 'Kode Outlet',
                        value: outlet?.kodeOutlet ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.radar_rounded,
                        label: 'Radius Absensi',
                        value: outlet != null
                            ? '${outlet.radiusMeter} meter'
                            : '-',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Informasi Fase Berikutnya ─────────────────────────────
              Card(
                elevation: 2,
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.amber.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.amber.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Fase 5 akan mengintegrasikan lokasi GPS dan fitur absensi check-in / check-out.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Tombol Logout ─────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari Akun'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
